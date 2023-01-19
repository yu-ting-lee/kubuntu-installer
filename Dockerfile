FROM ubuntu:22.04

LABEL maintainer=lee

RUN apt-get update -y

RUN apt-get install openssh-server -y
RUN apt-get install sudo -y

RUN useradd -ms /bin/bash user
RUN echo 'user:user' | chpasswd
RUN adduser user sudo

COPY init.sh /home/user/
RUN chmod +x /home/user/init.sh 

EXPOSE 22

CMD /home/user/init.sh
