FROM steamcmd/steamcmd:latest

# install deps
RUN useradd -m steam \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-utils \
    && apt-get install -y net-tools \
    && apt-get install -y nano \
    && apt-get install -y vim \
    && apt-get install -y \
        lib32gcc1 \
        libcap-dev \
        libcurl4 \
        libcurl4-openssl-dev \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

USER steam

ENV USER steam
ENV HOME /home/steam
ENV GAME dayz
ENV APPID 1042420
ENV STEAMACCOUNT anonymous
ENV STEAMPASSWORD ${1:+1}
ENV CPUCOUNT 2
ENV PORT 2302

WORKDIR /home/steam

# permissions
RUN mkdir ${HOME}/${game} && \
    mkdir ${HOME}/profile && \
    mkdir ${HOME}/battleye && \
    chown -R steam:steam ${HOME}

# Exposed Ports
# game
EXPOSE ${PORT}/udp
EXPOSE 2302/udp
EXPOSE 2303/udp
EXPOSE 2304/udp
EXPOSE 2305/udp
# steam
EXPOSE 8766/udp
EXPOSE 27016/udp
# rcon
EXPOSE 2310

# update steamcmd
RUN steamcmd +quit

# define entrypoint
COPY entry.sh ${HOME}/entry.sh

ENTRYPOINT "${HOME}/entry.sh"
