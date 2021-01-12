ARG PARENT_IMAGE=openmicroscopy/omero-server:latest
FROM ${PARENT_IMAGE}
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root

RUN yum -y install \
    git \
    && yum clean all

ADD 01-default-extras.omero /opt/omero/server/config/

USER omero-server
