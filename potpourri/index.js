const lib = require('lib');
const core = require('@actions/core');
const exec = require('@actions/exec');

const target = core.getInput('target', { required: true });
const token = core.getInput('clone_token', { required: true });

// Mask the clone token, because it is part of the clone URL which shows up
// in git error messages
core.setSecret(token);

let stderr = '';

// Perform the low-level settings extraction and save the output
exec.exec('bash', [`${__dirname}/../run.sh`, target, token], {
  silent: true,
  listeners: {
    stdout: (data) => { process.stdout.write(data); },
    stderr: (data) => { stderr += data.toString(); }
  }
}).then(() => {
  process.exit(0);
}).catch((err) => {
  if (err) {
    core.error(err.message);
  }

  stderr.split(/\n/).forEach((line) => core.warning(line));
  process.exit(1);
});
