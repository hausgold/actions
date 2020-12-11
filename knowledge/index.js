const lib = require('lib');
const core = require('@actions/core');
const exec = require('@actions/exec');

// Enable unsecure commands for now
lib.exportVariable('ACTIONS_ALLOW_UNSECURE_COMMANDS', 'true');

const app = core.getInput('app', { required: true });
const token = core.getInput('clone_token', { required: true });
const isPrivate = (name) => /PASSWORD|PRIVATE|SECRET|TOKEN/i.test(name);

let stdout = '';
let stderr = '';

// Perform the low-level settings extraction and save the output
exec.exec('bash', [`${__dirname}/../settings.sh`, app, token], {
  silent: true,
  listeners: {
    stdout: (data) => { stdout += data.toString(); },
    stderr: (data) => { stderr += data.toString(); }
  }
}).then(() => {
  // Sanitize the environment variables for export
  let env = stdout.trim().split(/\n/).reduce((memo, cur) => {
    let parts = cur.trim().split('=');
    let key = parts.shift();
    let val = parts.join('=').replace(/^['"]|['"]$/g, '');
    memo[key] = val;
    return memo;
  }, {});

  // Register all environment variables and register secrets for masking
  for (let [key, val] of Object.entries(env)) {
    lib.exportVariable(key, val);
    if (isPrivate(key)) {
      core.setSecret(val);
    }
    core.info(`exported environment variable: ${key}=${val}`)
  }

  process.exit(0);
}).catch((err) => {
  if (err) {
    core.error(err.message);
    core.error(err.stack);
  }

  stderr.split(/\n/).forEach((line) => core.warning(line));
  process.exit(1);
});
