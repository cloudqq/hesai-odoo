# Please note that this Dockerfile is used for testing nightly builds and should
# not be used to deploy Odoo
FROM debian:jessie
MAINTAINER Mario Tao <mario@hesaitech.com>

RUN apt-get update && \
	apt-get install -y locales && \
	rm -rf /var/lib/apt/lists/*

# Reconfigure locales such that postgresql uses UTF-8 encoding
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update -qq &&  \
	apt-get upgrade -qq -y && \
	apt-get install \
    curl \
		postgresql-client \
		adduser \
		node-less \
		libxml2-dev \
		libxslt1-dev \
		libldap2-dev \
		libsasl2-dev \
		libssl-dev \
		libjpeg-dev \
		python-dev \
		python-pip \
		build-essential \
    libmagickwand-dev \
    libfontconfig1 \
    libxrender1 \
    ttf-wqy-zenhei \
    ttf-wqy-microhei \
		python -y  \
    && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
    && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
    && dpkg --force-depends -i wkhtmltox.deb \
    && apt-get -y install -f --no-install-recommends \
    && dpkg --force-depends -i wkhtmltox.deb && \
	easy_install --upgrade pip && \
	rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

COPY requirements.txt /opt/odoo/requirements.txt

RUN pip install -r /opt/odoo/requirements.txt

RUN useradd -ms /bin/bash odoo

COPY ./src /opt/odoo/

WORKDIR /opt/odoo

RUN chown -R odoo:odoo /opt/odoo
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

RUN cp /opt/odoo/odoo-bin /usr/bin/odoo

RUN echo "PS1=\"[\u@odoo-release-10.0] # \"" > ~/.bashrc

RUN mkdir -p /mnt/extra-addons &&\
    mkdir -p /opt/odoo/.local/share/Odoo/filestore && \
    mkdir -p /opt/odoo/.local/share/Odoo/sessions && \
    mkdir -p /opt/odoo/.local/share/Odoo/addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /opt/odoo/.local

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf
ENV PATH=/opt/odoo:$PATH

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo-bin"]



