FROM python:3.9.10-slim-buster

RUN adduser sanic -system -group

COPY requirements.txt .

RUN pip3 install -r requirements.txt \
&& rm requirements.txt

WORKDIR /sanic

COPY server.py .

EXPOSE 46547

USER sanic
ENTRYPOINT ["python3", "server.py"]