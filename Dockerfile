
# Build stage
FROM ruby:2.7.4-alpine3.14 as build

ENV RAILS_ROOT=/app
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

RUN apk add --update --no-cache \
    alpine-sdk \
    nodejs-current \
    python3 \
    git \
    yarn

WORKDIR $RAILS_ROOT

COPY package.json yarn.lock Gemfile Gemfile.lock $RAILS_ROOT/

COPY vendor $RAILS_ROOT/vendor

RUN yarn install --pure-lockfile

RUN gem install bundler \
    && bundle install --without development --path=vendor/bundle \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    && find vendor/bundle/ruby/ -path "*/cache/*.gem" -delete \
    && find vendor/bundle/ruby/ -path "*/gems/*.c" -delete \
    && find vendor/bundle/ruby/ -path "*/gems/*.o" -delete

COPY . $RAILS_ROOT

RUN yarn bundle

RUN bundle exec rails assets:precompile

# Remove folders not needed in resulting image
RUN rm -rf node_modules tmp/cache

# Final image
FROM ruby:2.7.4-alpine3.14

ENV RAILS_ENV=production
ENV RAILS_ROOT=/app
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

WORKDIR $RAILS_ROOT

RUN apk add --update --no-cache \
    tzdata \
    nodejs-current

COPY --from=build $RAILS_ROOT $RAILS_ROOT

EXPOSE 3000

ENTRYPOINT [ "./docker/entrypoint.sh" ]

CMD [ "start" ]