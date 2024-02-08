# docker build --no-cache --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" -t clipkit .

FROM ubuntu:22.04

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
ENV RAILS_ENV=development
ENV RAILS_LOG_TO_STDOUT=true

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-utils \
      build-essential \
      ca-certificates \
      curl \
      git \
      imagemagick \
      libcairo2-dev \
      libffi-dev \
      libfontconfig1 \
      libgirepository1.0-dev \
      libglib2.0-dev \
      libidn11-dev \
      libpoppler-glib-dev \
      libpq-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libyaml-dev \
      musl \
      openssh-client \
      postgresql-14 \
      postgresql-contrib-14 \
      rustc \
      sudo \
      zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /clipkit

ARG SSH_PRIVATE_KEY

RUN mkdir /root/.ssh && \
    echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    git clone -b master git@github.com:bitarts/clipkit.git /clipkit && \
    rm -rf /root/.ssh

RUN echo "local all all trust" > /etc/postgresql/14/main/pg_hba.conf && \
    echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/14/main/pg_hba.conf && \
    echo "host all all ::/0 trust" >> /etc/postgresql/14/main/pg_hba.conf && \
    echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf

RUN git clone https://github.com/anyenv/anyenv /opt/anyenv && \
    echo "export PATH=\"/opt/anyenv/bin:./bin:$PATH\"" >> /etc/profile.d/anyenv.sh && \
    echo "eval \"\$(anyenv init -)\"" >> /etc/profile.d/anyenv.sh && \
    . /etc/profile.d/anyenv.sh && \
    yes | anyenv install --init && \
    anyenv install rbenv && \
    anyenv install nodenv && \
    . /etc/profile.d/anyenv.sh && \
    rbenv install 3.1.4 && \
    rbenv global 3.1.4 && \
    nodenv install 18.17.0 && \
    nodenv global 18.17.0 && \
    nodenv rehash && \
    corepack enable

COPY clipkit/config/master.key /clipkit/config/master.key

RUN cp -n config/database.yml.sample config/database.yml && \
    cp -n config/application.yml.sample config/application.yml && \
    echo "  host_name: localhost" >> config/application.yml && \
    rm config/initializers/rack_profiler.rb && \
    . /etc/profile.d/anyenv.sh && \
    bundle install --path vendor/bundle -j2 && \
    yarn install --immutable --network-timeout 600000 --non-interactive && \
    yarn cache clean

RUN service postgresql start && \
    sudo -u postgres createuser -s clipkit && \
    . /etc/profile.d/anyenv.sh && \
    bin/rails db:create && \
    bin/rails db:migrate && \
    bin/rails db:seed && \
    bin/rails assets:precompile webpacker:compile && \
    service postgresql stop

RUN echo "web: RAILS_SERVE_STATIC_FILES=true WAIT_FOR_DATABASE=true bin/rails server -b 0.0.0.0 -p 3000" > Procfile && \
    echo "dev_theme: WAIT_FOR_DATABASE=true bin/rails runner 'DevThemeListener.new(path: \"./dev-theme/dest\").start'" >> Procfile && \
    echo "esbuild: cd dev-theme/node && node esbuild.js" >> Procfile && \
    echo "postgres: sudo -u postgres /usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf" >> Procfile

EXPOSE 3000

CMD /bin/bash
