FROM steamcmd/steamcmd:latest

# install deps
RUN useradd -m steam \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-utils \
    && apt-get install -y net-tools \
    && apt-get install -y \
        lib32gcc1 \
        libcap-dev \
        libcurl4 \
        libcurl4-openssl-dev \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

USER steam

WORKDIR /home/steam

COPY --chown=steam:steam dayz_install.txt /home/steam

# permissions
RUN mkdir /home/steam/dayz && \
    mkdir /home/steam/profile && \
    chown -R steam:steam /home/steam

# game
EXPOSE 2302/udp
EXPOSE 2303/udp
EXPOSE 2304/udp
EXPOSE 2305/udp
# steam
EXPOSE 8766/udp
EXPOSE 27016/udp
# rcon (preferred)
EXPOSE 2310

# update steamcmd & validate user permissions
ENV USER steam
ENV HOME /home/steam
RUN steamcmd +quit

# reset cmd & define entrypoint
COPY entry.sh /home/steam/entry.sh
ENTRYPOINT [ "/home/steam/entry.sh" ]