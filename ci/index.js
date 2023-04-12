const lib = require('lib');
const core = require('@actions/core');
const exec = require('@actions/exec');

const settingsApp = core.getInput('settings').split('/').slice(-1)[0];
const target = core.getInput('target', { required: true });
const token = core.getInput('clone_token', { required: true });

// Export the clone token for our children
process.env['INPUT_CLONE_TOKEN'] = token;

(async function() {
  // Run the settings action if we should
  if (settingsApp) {
    await core.group(
      `Fetch all application settings for ${settingsApp}`,
      () => {
        // When settings should be loaded, we require
        // the secret key for decryption
        const secret_key = core.getInput('settings_secret_key', {
          required: true
        });

        process.env['INPUT_SECRET_KEY'] = secret_key;
        process.env['INPUT_APP'] = settingsApp;
        return exec.exec('node', [
          `${__dirname}/../../settings/dist/index.js`
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
