FROM ruby:2.6.3

RUN apt-get update && apt-get -y install build-essential nodejs postgresql postgresql-contrib

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"


RUN mkdir /app
WORKDIR /app

COPY . .
RUN rm -f ./Gemfile.lock

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]


LABEL maintainer="Alexander Chernov <boss@beone.software>"
EXPOSE 3000
CMD puma -C config/puma.rb