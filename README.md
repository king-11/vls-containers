# VLS Containers

## Volume Creation

```
docker container create bitcoin_data
docker container create lightning_data
```

## Docker Compose Run

```
docker compoe -f docker-compose.yml up --build
```

### References

- [bitcoind](https://github.com/ruimarinho/docker-bitcoin-core/blob/master/23/alpine/Dockerfile) by @ruimarinho
- [lightningd with clboss](https://github.com/tsjk/docker-core-lightning/blob/main/Dockerfile) by @tsjk
- [elements lightning](https://github.com/ElementsProject/lightning/blob/master/contrib/docker/Dockerfile.alpine) by @ElementsProject
- [docker compose](https://github.com/LukasBahrenberg/lightning-dockercompose/blob/master/docker-compose.yaml) by @LukasBahrenberg