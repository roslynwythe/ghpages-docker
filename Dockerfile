### Build Stage 1
FROM ruby:2.7.3-alpine3.13 AS build
LABEL maintainer "Jordon Bedwell <jordon@envygeeks.io>"

COPY copy/all /

#
# EnvVars
# Ruby
#

ENV BUNDLE_HOME=/usr/local/bundle
ENV GEM_BIN=/usr/gem/bin
ENV GEM_HOME=/usr/gem

#
# EnvVars
# Image
#

ENV JEKYLL_VAR_DIR=/var/jekyll
ENV JEKYLL_DATA_DIR=/srv/jekyll
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
  bash \
  su-exec \
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

RUN unset GEM_HOME && unset GEM_BIN && yes | gem install --force bundler
RUN gem install github-pages -- \
    --use-system-libraries

#
# Gems
# User
#

RUN addgroup -Sg 1000 jekyll
RUN adduser  -Su 1000 -G \
  jekyll jekyll

#
# Remove development packages on minimal.
# And on pages.  Gems are unsupported.
#

RUN apk --no-cache del \
  linux-headers \
  openjdk8-jre \
  zlib-dev \
  build-base \
  libxml2-dev \
  libxslt-dev \
  readline-dev \
  imagemagick-dev\
  libffi-dev \
  ruby-dev \
  yaml-dev \
  zlib-dev \
  libffi-dev \
  vips-dev \
  vips-tools \
  cmake

RUN mkdir -p $JEKYLL_VAR_DIR
RUN mkdir -p $JEKYLL_DATA_DIR
RUN chown -R jekyll:jekyll $JEKYLL_DATA_DIR
RUN chown -R jekyll:jekyll $JEKYLL_VAR_DIR
RUN chown -R jekyll:jekyll $BUNDLE_HOME
RUN rm -rf /home/jekyll/.gem
RUN rm -rf $BUNDLE_HOME/cache
RUN rm -rf $GEM_HOME/cache
RUN rm -rf /root/.gem

### Build Stage 2
FROM ruby:2.7.3-alpine3.13

# Copy shell scripts from build stage
COPY --from=build /usr/jekyll/bin /usr/jekyll/bin

# Copy required binaries and installed gems from build stage to final stage (I think???)
COPY --from=build $BUNDLE_HOME $BUNDLE_HOME
COPY --from=build $GEM_HOM $GEM_HOME

# Work around rubygems/rubygems#3572
RUN mkdir -p /usr/gem/cache/bundle
RUN chown -R jekyll:jekyll \
  /usr/gem/cache/bundle

CMD ["jekyll", "--help"]
ENTRYPOINT ["/usr/jekyll/bin/entrypoint"]
WORKDIR /srv/jekyll
VOLUME  /srv/jekyll
EXPOSE 35729
EXPOSE 4000
