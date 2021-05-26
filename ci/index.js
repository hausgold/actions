const lib = require('lib');
const core = require('@actions/core');
const exec = require('@actions/exec');

const settings = core.getInput('settings');
const target = core.getInput('target', { required: true });
const token = core.getInput('clone_token', { required: true });

// Export the clone token for our children
process.env['INPUT_CLONE_TOKEN'] = token;

(async function() {
  // Run the knowledge action if we should
  if (settings) {
    await core.group(
      `Fetch all application settings from knowledge for ${settings}`,
      () => {
        process.env['INPUT_APP'] = settings;
        return exec.exec('node', [
          `${__dirname}/../../knowledge/dist/index.js`
        ], { env: lib.runtimeEnv() }).catch(() => process.exit(1));
      }
    );
  }

  // Run the potpourri action
  await core.group(`Provision Potpourri ${target} target`, async () => {
    process.env['INPUT_TARGET'] = target;
    return exec.exec('node', [
      `${__dirname}/../../potpourri/dist/index.js`
    ], { env: lib.runtimeEnv() }).catch(() => process.exit(1));
  });
}());
