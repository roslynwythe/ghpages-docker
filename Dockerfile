### Build Stage 1
FROM ruby:2.7.3-alpine3.13 AS build
LABEL maintainer "Jordon Bedwell <jordon@envygeeks.io>"

#
# EnvVars
# Ruby
#

ENV GEM_BIN=/usr/gem/bin
ENV GEM_HOME=/usr/gem

#
# Packages
# Dev
#

RUN apk --no-cache add \
  zlib-dev \
  libffi-dev \
  build-base \
  libxml2-dev \
  imagemagick-dev \
  readline-dev \
  libxslt-dev \
  libffi-dev \
  yaml-dev \
  zlib-dev \
  vips-dev \
  vips-tools \
  sqlite-dev \
  cmake

#
# Packages
# Main
#

RUN apk --no-cache add \
  linux-headers \
  openjdk8-jre \
  less \
  zlib \
  libxml2 \
  readline \
  libxslt \
  libffi \
  git \
  nodejs \
  tzdata \
  shadow \
  npm \
  libressl \
  yarn

#
# Gems
# Update
#

RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN unset GEM_HOME && unset GEM_BIN && \
  yes | gem update --system

#
# Gems
# Main
#

RUN gem install github-pages -- \
    --use-system-libraries


### Build Stage 2
FROM ruby:2.7.3-alpine3.13

# Copy shell scripts
COPY copy/all /

#
# EnvVars
# Ruby
#

ENV GEM_BIN=/usr/gem/bin
ENV GEM_HOME=/usr/gem

#
# EnvVars
# Image
#

ENV JEKYLL_BIN=/usr/jekyll/bin

#
# EnvVars
# System
#

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV TZ=America/Chicago
ENV PATH="$JEKYLL_BIN:$PATH"
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US

# Reinstall to see if I can get the container running... remove these dupe lines later
RUN apk --no-cache add \
  bash \
  su-exec

# Copy required binaries and installed gems from build stage to final stage (I think???)
COPY --from=build /usr/gem/ /usr/gem/

RUN addgroup -Sg 1000 jekyll
RUN adduser  -Su 1000 -G \
  jekyll jekyll

RUN mkdir -p /var/jekyll
RUN mkdir -p /srv/jekyll
RUN chown -R jekyll:jekyll /srv/jekyll
RUN chown -R jekyll:jekyll /var/jekyll
RUN rm -rf /home/jekyll/.gem
RUN rm -rf /usr/gem/cache
RUN rm -rf /root/.gem

# # Work around rubygems/rubygems#3572
# RUN mkdir -p /usr/gem/cache/bundle
# RUN chown -R jekyll:jekyll \
#   /usr/gem/cache/bundle

CMD ["jekyll", "--help"]
ENTRYPOINT ["/usr/jekyll/bin/entrypoint"]
WORKDIR /srv/jekyll
VOLUME  /srv/jekyll
EXPOSE 35729
EXPOSE 4000
