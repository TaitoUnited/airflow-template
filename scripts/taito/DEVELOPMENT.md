# Development

This file has been copied from [AIRFLOW-TEMPLATE](https://github.com/TaitoUnited/AIRFLOW-TEMPLATE/). Keep modifications minimal and improve the [original](https://github.com/TaitoUnited/AIRFLOW-TEMPLATE/blob/dev/scripts/taito/DEVELOPMENT.md) instead. Project specific conventions are located in [README.md](../../README.md#conventions). See the [Taito CLI tutorial](https://taitounited.github.io/taito-cli/tutorial) for more thorough development instructions.

Table of contents:

- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Version control](#version-control)
- [Database migrations](#database-migrations)
- [Deployment](#deployment)
- [Upgrading](#upgrading)
- [Configuration](#configuration)

## Prerequisites

- [Node.js (LTS version)](https://nodejs.org/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Taito CLI](https://taitounited.github.io/taito-cli/) (or see [TAITOLESS.md](TAITOLESS.md))
- Some editor plugins depending on technology (e.g. Flake8 and Black plugins for linting and formatting Python code)

## Quick start

> TIP: Make sure your cloud auth is still in effect with `taito auth:dev` and start application in a cleaned and initialized local environment with a single command: `taito develop`. This is essentially the same thing as running `taito env apply --clean`, `taito start --clean`, and `taito init`. If the application fails to start, run `taito trouble` to see troubleshooting.

In case you need some secrets from dev, make sure your cloud authentication is still in effect:

    taito auth:dev

Create local environment by installing some libraries and generating secrets (add `--clean` to recreate clean environment):

    taito env apply

Start containers (add `--clean` to make a clean rebuild and to discard all data, add `--init` to run `taito init` automatically after start):

    taito start

Make sure that everything has been initialized (e.g database, generated schemas) (add `--clean` to make a clean reinit):

    taito init

Show user accounts and other information that you can use to log in:

    taito info

Open airflow GUI in browser:

    taito open airflow

Access database:

    taito db connect                        # access using a command-line tool
    taito db proxy                          # access using a database GUI tool
                                            # look docker-compose.yaml for database user credentials
    taito db import: ./database/file.sql    # import a sql script to database

TODO running tests...

Start shell on a container:

    taito shell:airflow

Restart and stop:

    taito restart:airflow                   # restart the airflow container
    taito restart                           # restart all containers
    taito stop                              # stop all containers

List all project related links and open one of them in browser:

    taito open -h
    taito open NAME

TODO checking code quality...

    taito code check
    <!-- TODO
    taito code check:admin
    taito code check:client
    taito code check:server
    -->

The commands mentioned above work also for server environments (`f-NAME`, `dev`, `test`, `uat`, `stag`, `canary`, `prod`). Some examples for dev environment:

    taito auth:dev                          # Authenticate to dev
    taito env apply:dev                     # Create the dev environment
    taito push                              # Push changes to current branch (dev)
    taito open builds:dev                   # Show build status and build logs
    taito open airflow:dev                  # Open airflow GUI in browser
    taito info:dev                          # Show info
    taito status:dev                        # Show status of dev environment
    taito logs:airflow:dev                  # Tail logs of airflow container
    taito open logs:dev                     # Open logs on browser
    taito shell:airflow:dev                 # Start a shell on airflow container
    taito init:dev --clean                  # Clean reinit for dev environment
    taito db connect:dev                    # Access database on command line
    taito db proxy:dev                      # Start a proxy for database access
    taito secret show:dev                   # Show secrets (e.g. database user credentials)
    taito db rebase:dev                     # Rebase database by redeploying all migrations
    taito db import:dev ./database/file.sql # Import a file to database
    taito db dump:dev                       # Dump database to a file
    taito db log:dev                        # Show database migration logs
    taito db revert:dev XXX                 # Revert database to change XXX
    taito db deploy:dev                     # Deploy data migrations to database
    taito db recreate:dev                   # Recreate database
    taito db diff:dev test                  # Show diff between dev and test schemas
    taito db copy between:test:dev          # Copy test database to dev

Run `taito -h` to get detailed instructions for all commands. Run `taito COMMAND -h` to show command help (e.g `taito db -h`, `taito db import -h`). For troubleshooting run `taito trouble`. See [README.md](../../README.md) for project specific conventions and documentation.

> If you run into authorization errors, authenticate with the `taito auth:ENV` command.

> It's common that idle applications are run down to save resources on non-production environments. If your application seems to be down, you can start it by running `taito start:ENV`, or by pushing some changes to git.

## Database migrations

TODO: Perhaps we should use sqitch to sync user accounts and other data between environments?

Add a new migration:

1. Add a new step to migration plan:

   `taito db add NAME`, for example: `taito db add role_enum`

2. Modify database/deploy/NAME.sql, database/revert/NAME.sql and database/verify/NAME.sql

3. Deploy the change to your local database:

   `taito db deploy`

The CI/CD tool will deploy your database changes automatically to servers once you push your changes to git. Database migrations are executed using sqitch. More instructions on sqitch: [Sqitch tutorial](https://metacpan.org/pod/sqitchtutorial)

## Deployment

Container images are built for dev and feature branches only. Once built and tested successfully, the container images will be deployed to other environments on git branch merge:

- **pr-NNN**: Push to the branch of a pull-request.
- **dev**: Push to the `dev` branch.
- **test**: Merge changes to the `test` branch using fast-forward.
- **uat**: Merge changes to the `uat` branch using fast-forward.
- **stag**: Merge changes to the `stag` branch using fast-forward.
- **canary**: Merge changes to the `canary` branch using fast-forward. NOTE: Canary environment uses production resources (database, storage, 3rd party services) so be careful with database migrations.
- **prod**: Merge changes to the `master` branch using fast-forward. Version number and release notes are generated automatically by the CI/CD tool.

Simple projects require only two environments: **dev** and **prod**. You can list the environments with `taito env list`.

You can use the taito commands to manage branches, builds, and deployments. Run `taito env -h`, `taito feat -h`, `taito hotfix -h`, and `taito deployment -h` for instructions. Run `taito open builds` to see the build logs. See [version control](https://taitounited.github.io/taito-cli/tutorial/03-version-control) chapter of the [Taito CLI tutorial](https://taitounited.github.io/taito-cli/tutorial) for some additional information.

> Automatic deployment might be turned off for critical environments (`ci_exec_deploy` setting in `scripts/taito/env-*.sh`). In such case the deployment must be run manually with the `taito -a deployment deploy:prod VERSION` command using a personal admin account after the CI/CD process has ended successfully.

## Upgrading

Run `taito project upgrade`. The command copies the latest versions of reusable Helm charts, terraform templates and CI/CD scripts to your project folder, and also this README.md file. You should not make project specific modifications to them as they are designed to be reusable and easily configurable for various needs. Improve the originals instead, and then upgrade.

> TIP: You can use the `taito -o ORG project upgrade` command also for moving the project to a different platform (e.g. from AWS to GCP).

## Configuration

See [CONFIGURATION.md](CONFIGURATION.md).
