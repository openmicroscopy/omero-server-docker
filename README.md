OMERO.server Docker
===================

[![Actions Status](https://github.com/ome/omero-server-docker/workflows/Build/badge.svg)](https://github.com/ome/omero-server-docker/actions)

A CentOS 7 based Docker image for OMERO.server. The administrator account is named "root" with a
default password of "omero". This can be changed by setting the `ROOTPASS` environment variable.

Also see [SUPPORT.md](./SUPPORT.md)

Running OMERO with docker-compose
---------------------------------

The [omero-deployment-examples repository](https://github.com/ome/omero-deployment-examples/)
contains a number of different ways of deployment OMERO. Unless you are looking for something
specific, *we suggest starting with [docker-example-omero](https://github.com/ome/docker-example-omero).*

Running the images (manual)
---------------------------

To run the Docker images start a postgres DB:

    docker run -d --name postgres -e POSTGRES_PASSWORD=postgres postgres

Then run OMERO.server passing the database configuration parameters if they differ from the defaults.
This example uses the default `postgres` system database for convenience, in practice you may want to create your own database.

    docker run -d --name omero-server --link postgres:db \
        -e CONFIG_omero_db_user=postgres \
        -e CONFIG_omero_db_pass=postgres \
        -e CONFIG_omero_db_name=postgres \
        -e ROOTPASS=omero-root-password \
        -p 4063:4063 -p 4064:4064 \
        openmicroscopy/omero-server


Configuration variables
-----------------------

All [OMERO configuration properties](https://docs.openmicroscopy.org/latest/omero/sysadmins/config.html) can be set be defining environment variables `CONFIG_omero_property_name=`.
Since `.` is not allowed in a variable name `.` must be replaced by `_`, and `_` by `__`, for example

    -e CONFIG_omero_web_public_enabled=false


Configuration files
-------------------

Additional configuration files for OMERO can be provided by mounting files into `/opt/omero/server/config/`.
Files ending with `.omero` will be loaded with `omero load`.

For example:

    docker run -d -v
        /config/extra.omero:/opt/omero/server/config/extra.omero:ro
        openmicroscopy/omero-server

Parameters required for initializing the server such as database configuration *must* be set using environment variables.


Default volumes
---------------

- `/opt/omero/server/OMERO.server/var`: The OMERO.server `var` directory, including logs
- `/OMERO`: The OMERO data directory

When using bind mounts, ensure that the ownership and permissions on the host are set as follows:

- host folder mapped to `/opt/omero/server/OMERO.server/var`: UID/GID: 1000/997 `drwxr-xr-x`
- host folder mapped to `/OMERO`: UID/GID: 1000/0 `drwxr-xr-x`


Exposed ports
-------------

- 4063
- 4064


Example with named volumes
--------------------------

    docker volume create --name omero-db
    docker volume create --name omero-data

    docker run -d --name postgres -e POSTGRES_PASSWORD=postgres
        -v omero-db:/var/lib/postgresql/data postgres
    docker run -d --name omero-server --link postgres:db
        <-e CONFIG_omero_db_ ...>
        -v omero-data:/OMERO
        -p 4063:4063 -p 4064:4064 openmicroscopy/omero-server


Running without links
---------------------

As an alternative to running with `--link` the address of the database can be specified using the variable `CONFIG_omero_db_host`
