const fs = require('fs');
const core = require('@actions/core');
const runtimeEnvPath = '/tmp/Envfile.runtime';

// Fetch the current runtime environment bundle and return the parsed object.
// When it does not yet exists we just return an empty object.
const runtimeEnvBase = () => {
  if (!fs.existsSync(runtimeEnvPath)) { return {}; }
  return JSON.parse(fs.readFileSync(runtimeEnvPath, 'utf8'));
};

// Build a runtime environment by our own environment and the runtime
// environment. This allows us to overcome the children-parent environment
// barrier.
const runtimeEnv = (merge) => {
  if (!merge) { merge = runtimeEnvBase(); }
  return Object.assign(Object.assign({}, process.env), merge);
};

// Save the environment variable to the runtime Envfile. This is used by
// hausgold/actions to bundle multiple actions in one execution. This is
// needed because the parent process environment cannot be updated by its
// children. With this approach we make it possible.
const exportVariable = (key, val) => {
  core.exportVariable(key, val);
  let merge = {};
  merge[key] = val;
  fs.writeFileSync(runtimeEnvPath, JSON.stringify(runtimeEnv(merge)));
};

exports.runtimeEnv = runtimeEnv;
exports.exportVariable = exportVariable;
