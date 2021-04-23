FROM ubuntu:16.04

RUN apt-get update && apt-get install -y clang build-essential wget git sudo
RUN git clone https://github.com/plaurent/gnustep-build
RUN cp gnustep-build/*.sh .
RUN cp gnustep-build/ubuntu-16.04-clang-9.0-runtime-2.0-ARM/*.sh .
RUN chmod +x *.sh
RUN /bin/bash -c "./GNUstep-buildon-ubuntu1604_arm.sh"

CMD [ "/bin/bash", "-c", "export PS1=allow_bash_to_run; source ~/.bashrc; ./demo.sh" ]
