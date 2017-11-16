FROM ruby:2.4.1-alpine

# ~~~~ Set up the environment ~~~~
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /gem/
WORKDIR /gem/
ADD . /gem/

RUN apk update && \
  apk add --no-cache git && \
  touch ~/.gemrc && \
  echo "gem: --no-ri --no-rdoc" >> ~/.gemrc && \
  gem install rubygems-update && \
  update_rubygems && \
  gem install bundler && \
  bundle install

# Import the gem source code
VOLUME .:/gem/

ENTRYPOINT ["bundle", "exec"]
CMD ["rake", "-T"]
