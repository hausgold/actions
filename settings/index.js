const lib = require('lib');
const core = require('@actions/core');
const exec = require('@actions/exec');

const app = core.getInput('app', { required: true }).split('/').slice(-1)[0];
const token = core.getInput('clone_token', { required: true });
const secret_key = core.getInput('secret_key', { required: true });

const filterList = [
  'API_KEY', 'CREDENTIAL', 'ENCRYPTION', 'ghp_', 'PASSWORD',
  'PRIVATE', 'SECRET', 'TOKEN', 'CERTIFICATE', 'SLACK_.*_CHANNEL',
  'SEARCH_KEY', 'ADMIN_KEY'
];
const filterPattern = new RegExp(filterList.join('|'), 'i');
const isPrivate = (name) => filterPattern.test(name);

let stdout = '';
let stderr = '';

// Export some environment variables for the +settings.sh+ script, they are
// private to this process children
process.env.CLONE_TOKEN = token;
process.env.SECRET_KEY = secret_key;

// Perform the low-level settings extraction and save the output
exec.exec('bash', [`${__dirname}/../settings.sh`, app], {
  silent: true,
  listeners: {
    stdout: (data) => { stdout += data.toString(); },
    stderr: (data) => { stderr += data.toString(); }
  }
}).then(() => {
  // Sanitize the environment variables, then register them for export
  stdout.trim().split(/\n/).forEach((cur) => {
    let parts = cur.trim().split('=');
    let key = parts.shift();
    let val = parts.join('=').replace(/^['"]|['"]$/g, '').replace('\\$', '$');

    lib.exportVariable(key, val);

    if (isPrivate(key) && val != '') {
      core.setSecret(val);
    }

    core.info(`exported environment variable: ${key}=${val}`)
  });

  process.exit(0);
}).catch((err) => {
  if (err) {
    core.error(err.message);
    core.error(err.stack);
  }

  stderr.split(/\n/).forEach((line) => core.warning(line));
  process.exit(1);
});
