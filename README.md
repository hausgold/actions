![Actions](doc/assets/project.svg)

> [!NOTE]
> This version is deprecated. Please upgrade to the [latest `@v[MAJOR]`
> branch](https://github.com/hausgold/actions/branches/all).

This project is dedicated to bundle our shared Github Actions and it serves
some trampoline actions to other HAUSGOLD internals which are not public.

- [Compound Actions](#compound-actions)
  - [Generic Continuous Delivery](#generic-continuous-delivery)
- [Standalone Actions](#standalone-actions)
  - [Fetch application settings](#fetch-application-settings)
  - [Run a Potpourri script](#run-a-potpourri-script)

## Compound Actions

We provide some compound actions to shortcut the configuration overhead on
Github Actions. Unfortunately, we are not allowed (at the time of writing,
2020-02) to use YAML anchors and aliases which result in heavy copy-paste
configurations. Our compound actions will ease the pain and provide easy to use
single-steps.

### Generic Continuous Delivery

This compound action makes use of the [Fetch application
settings](#fetch-application-settings) action and the [Run a Potpourri
script](#run-a-potpourri-script) action.

```yaml
steps:
  - name: Prepare the virtual environment
    uses: hausgold/actions/ci@master
    with:
      clone_token: '${{ secrets.CLONE_TOKEN }}'
      settings_secret_key: '${{ secrets.SETTINGS_SECRET_KEY }}'
      settings: '${{ github.event.repository.name }}'
      target: ci/sd-deploy
```

## Standalone Actions

Most commonly on Github Actions is the usage of standalone actions which are
performed on after another while having the user the configure each step, even
on multiple jobs.

### Fetch application settings

This action allows you to fetch the application settings from our
[Settings](https://github.com/hausgold/settings) repository by specifying the
application name and the Github clone token. Make sure your application
repository have set the `CLONE_TOKEN` secret correctly. Afterwards you
can access all settings via regular environment variables.

```yaml
steps:
  - name: Fetch all application settings
    uses: hausgold/actions/settings@master
    with:
      clone_token: '${{ secrets.CLONE_TOKEN }}'
      secret_key: '${{ secrets.SETTINGS_SECRET_KEY }}'
      app: '${{ github.event.repository.name }}'
```

### Run a Potpourri script

To set up the virtual environment with some ready to use recipes you can use
the Potpourri trampoline for your HAUSGOLD internal application. This will
fetch and build the Potpourri repository (5s) and run the desired script. See
the [Potpourri documentation](https://github.com/hausgold/potpourri) for
further details and a full list of supported targets.

```
steps:
  - name: Prepare the virtual environment
    uses: hausgold/actions/potpourri@master
    with:
      clone_token: '${{ secrets.CLONE_TOKEN }}'
      target: ci/sd-deploy
```
