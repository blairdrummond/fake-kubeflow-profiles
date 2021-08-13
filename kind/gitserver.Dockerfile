FROM node:alpine

RUN apk add --no-cache tini git \
    && yarn global add git-http-server \
    && adduser -D -g git git

WORKDIR /home/git/profiles.git

COPY --chown=1000:100 profiles /home/git/profiles.git/profiles

ENV GIT_USER="nancy"
ENV GIT_EMAIL="nancy@argoflow.ca"

RUN find . -name .gitignore -delete \
    && git config --global user.email "$GIT_EMAIL" \
    && git config --global user.namel "$GIT_NAME" \
    && git init \
    && git add . \
    && git commit -m 'Add profiles' \
    && chown -R git .

USER git

EXPOSE 8080
ENTRYPOINT ["tini", "--", "git-http-server", "-p", "8080", "/home/git"]
