FROM ruby:3.3-bullseye as base

RUN apt-get update -qq && \
    apt-get install -y build-essential apt-utils libpq-dev nodejs git

WORKDIR /real-estate-listings-api

# Copy dependency files from app subfolder
COPY real-estate-listings-api/Gemfile real-estate-listings-api/Gemfile.lock ./
RUN bundle install

ADD . real-estate-listings-api

ARG DEFAULT_PORT=3000

EXPOSE ${DEFAULT_PORT}


CMD ["rails", "server", "-b", "0.0.0.0"]
