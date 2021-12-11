FROM gitpod/workspace-full

USER gitpod

RUN sudo apt install -y rsync

RUN curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall
