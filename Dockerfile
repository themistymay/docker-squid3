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

RUN apt-get clean

COPY squid.conf.ssl /etc/squid3/squid.conf
COPY password	/etc/squid3/password
RUN chmod +x /etc/squid3/password

RUN mkdir /certs
WORKDIR /certs

ADD certs/intermediate.cert.pem squid.crt
ADD certs/intermediate.key.pem squid.key
RUN cat squid.key squid.crt > squid.pem
RUN cp squid.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

RUN mkdir -p /squid3/logs
RUN chown proxy /squid3
RUN chmod -R 777 /squid3

RUN mkdir -p /usr/local/squid/var/lib
RUN /usr/lib/squid3/ssl_crtd -c -s /usr/local/squid/var/lib/ssl_db
RUN chown -R proxy /usr/local/squid/var/lib/ssl_db

RUN chmod 4755 /usr/lib/squid3/pinger

RUN chmod -R 777 /var/log/squid3

# CMD ["/usr/local/squid/sbin/squid", "-NCd1zv", "-f", "/etc/squid3/squid.conf"]

COPY supervisord.conf /etc/supervisor/conf.d/squid3.conf

CMD [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf" ]
