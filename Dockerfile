#######################################################################
# Creates a base Centos 7 image with JBoss EAP-6.3.0                  #
#######################################################################

# Use the centos base image
FROM centos

MAINTAINER hionuth <ionut.hrinca@ing.ro>

# Update the system
#RUN yum -y update;yum clean all

##########################################################
# Install Java JDK
##########################################################
USER root
ADD ./jdk-distribution/jdk-7u79-linux-x64.rpm /tmp/jdk-distribution/jdk-7u79-linux-x64.rpm
RUN mkdir -p /tmp/jdk-distribution \
 && yum -y localinstall --nogpgcheck /tmp/jdk-distribution/jdk-7u79-linux-x64.rpm \
 && rm -rf /tmp/jdk-distribution

ENV JAVA_HOME /usr/java/jdk1.7.0_79

##########################################################
# Install zip
##########################################################
ADD ./zip/unzip-6.0-15.el7.x86_64.rpm /tmp/unzip-6.0-15.el7.x86_64.rpm
RUN yum -y localinstall --nogpgcheck /tmp/unzip-6.0-15.el7.x86_64.rpm \
 && rm -rf /tmp/unzip-6.0-15.el7.x86_64.rpm

##########################################################
# Create jboss user
##########################################################
RUN groupadd -r jboss && useradd -r -g jboss -m -d /home/jboss jboss

############################################
# Install EAP 6.3.0.GA
############################################
#RUN yum -y install zip unzip

USER jboss
ENV INSTALLDIR /home/jboss/EAP-6.3.0
ENV HOME /home/jboss

RUN mkdir $INSTALLDIR && \
   mkdir $INSTALLDIR/distribution && \
   mkdir $INSTALLDIR/resources

USER root
ADD distribution $INSTALLDIR/distribution
# ADD distribution-patches $INSTALLDIR/distribution-patches
RUN chown -R jboss:jboss /home/jboss && \
    find /home/jboss -type d -execdir chmod 770 {} \; && \
    find /home/jboss -type f -execdir chmod 660 {} \; 

USER jboss
RUN unzip $INSTALLDIR/distribution/jboss-eap-6.3.0.zip  -d $INSTALLDIR

############################################
# Create start script to run EAP instance
############################################
USER root
RUN echo "#!/bin/sh" >> $HOME/start.sh \
 && echo "echo JBoss EAP Start script" >> $HOME/start.sh \
 && echo "runuser -l jboss -c '$HOME/EAP-6.3.0/jboss-eap-6.3/bin/add-user.sh -s -u jbossadmin -p jboss@dmin1'" >> $HOME/start.sh \
 && echo "runuser -l jboss -c '$HOME/EAP-6.3.0/jboss-eap-6.3/bin/standalone.sh -c standalone-full.xml -b 0.0.0.0 -bmanagement 0.0.0.0'" >> $HOME/start.sh \
 && chmod +x $HOME/start.sh

############################################
# Remove install artifacts
############################################
RUN rm -rf $INSTALLDIR/distribution \
 && rm -rf $INSTALLDIR/distribution-patches \
 && rm -rf $INSTALLDIR/resources

############################################
# Add customization sub-directories (for entrypoint)
############################################
ADD modules  $INSTALLDIR/modules
RUN chown -R jboss:jboss $INSTALLDIR/modules
RUN find $INSTALLDIR/modules -type d -execdir chmod 770 {} \;
RUN find $INSTALLDIR/modules -type f -execdir chmod 660 {} \;

############################################
# Expose paths and start JBoss
############################################
EXPOSE 22 5455 9999 8080 5432 4447 5445 9990 3528

RUN mkdir /etc/jboss-as
RUN mkdir /var/log/jboss/
RUN chown jboss:jboss /var/log/jboss/

############################################
# Start JBoss in stand-alone mode
############################################
CMD /home/jboss/start.sh
