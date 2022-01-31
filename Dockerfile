FROM python:3.9.10-alpine

WORKDIR /sanic

USER root

RUN addgroup sanic && adduser -S -G sanic sanic

COPY requirements.txt .

RUN apk add --update --no-cache build-base \
&& pip3 install -r requirements.txt \ 	
&& apk del --no-cache build-base

USER sanic

COPY server.py .

EXPOSE 46547

CMD ["python3", "server.py"]