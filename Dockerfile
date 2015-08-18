FROM ubuntu:14.04
MAINTAINER Mike May <themistymay@gmail.com>

ENV VERSION_MAJOR_SQUID 3
ENV VERSION_MINOR_SQUID 5
ENV VERSION_PATCH_SQUID 3

ENV VERSION_SQUID $VERSION_MAJOR_SQUID.$VERSION_MINOR_SQUID.$VERSION_PATCH_SQUID

RUN apt-get update
RUN apt-get build-dep squid3 -y -q
RUN apt-get install -y -q wget libssl-dev

RUN mkdir -p /opt/squid-$VERSION_SQUID

WORKDIR /opt
RUN wget http://www.squid-cache.org/Versions/v$VERSION_MAJOR_SQUID/$VERSION_MAJOR_SQUID.$VERSION_MINOR_SQUID/squid-$VERSION_SQUID.tar.gz

RUN tar -xvf squid-$VERSION_SQUID.tar.gz

WORKDIR /opt/squid-$VERSION_SQUID
RUN ./configure --datadir=/usr/share/squid3 \
		--libexecdir=/usr/lib/squid3 \
		--sysconfdir=/etc/squid3 \
		--mandir=/usr/share/man \
		--enable-inline \
		--enable-async-io=8 \
		--enable-storeio="ufs,aufs,diskd,rock" \
		--enable-removal-policies="lru,heap" \
		--enable-delay-pools \
		--enable-cache-digests \
		--enable-underscores \
		--enable-icap-client \
		--enable-follow-x-forwarded-for \
		--enable-auth-basic="DB,fake,getpwnam,LDAP,NCSA,NIS,PAM,POP3,RADIUS,SASL,SMB" \
		--enable-auth-digest="file,LDAP" \
		--enable-auth-negotiate="kerberos,wrapper" \
		--enable-auth-ntlm="fake,smb_lm" \
		--enable-external-acl-helpers="file_userip,kerberos_ldap_group,LDAP_group,session,SQL_session,unix_group,wbinfo_group" \
		--enable-url-rewrite-helpers="fake" \
		--enable-eui \
		--enable-esi \
		--enable-icmp \
		--enable-zph-qos \
		--enable-ssl \
		--enable-ssl-crtd \
		--disable-translation \
		--with-swapdir=/var/spool/squid3 \
		--with-logdir=/var/log/squid3 \
		--with-pidfile=/var/run/squid3.pid \
		--with-filedescriptors=65536 \
		--with-large-files \
		--with-openssl \
		--with-default-user=proxy \
		--enable-linux-netfilter

RUN make
RUN make install

RUN apt-get install -yq supervisor
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d/

RUN apt-get clean

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY squid.conf /etc/squid3/squid.conf

#RUN chown proxy:proxy /etc/squid3/squid.conf
#RUN chmod a+r /etc/squid3/squid.conf

#
# ADD squid.conf /etc/squid/squid.conf
#
# RUN mkdir /certs
# WORKDIR /certs
#
# ADD inet.cert inet.cert
# ADD inet.csr inet.csr
# ADD inet.private inet.private
#
# RUN /usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db
# RUN chown squid:squid /var/lib/ssl_db
#
# RUN touch /var/run/squid.pid
# RUN chmod 755 /var/run/squid.pid
# RUN chown squid:squid /var/run/squid.pid
#
# # fix permissions on the log dir
# RUN mkdir -p /var/log/squid
# RUN chmod -R 755 /var/log/squid
RUN chown -R proxy:proxy /var/log/squid3
RUN chmod 4755 /usr/lib/squid3/pinger
#
# # fix permissions on the cache dir
# RUN mkdir -p /var/spool/squid
# RUN chown -R squid:squid /var/spool/squid

EXPOSE 3128
#USER proxy
#CMD ["/usr/local/squid/sbin/squid", "-f", "/etc/squid3/squid.conf"]
CMD ["/usr/bin/supervisord", "-n"]
