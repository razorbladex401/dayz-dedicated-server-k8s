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

WORKDIR /home/steam

# permissions
RUN mkdir /home/steam/dayz && \
    mkdir /home/steam/profile && \
    mkdir /home/steam/battleye && \
    chown -R steam:steam /home/steam

# Exposed Ports
# game
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
ENV USER steam
ENV HOME /home/steam
RUN steamcmd +quit

# define entrypoint
COPY entry.sh /home/steam/entry.sh
ENTRYPOINT [ "/home/steam/entry.sh" ]
