FROM node:14.17

COPY src /opt/app

RUN apt-get update && apt install nano

CMD ["node","/opt/app/index.js"]
