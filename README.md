# How to configure and start Accelerator services for local development

## Prerequisites

1. A Docker runtime on your development machine.
2. A Kubernetes cluster, either on your development machine or remotely.
   * **Warning:** Docker Desktop on Windows has issues with building and Wine.
   * On Linux, success has been had with Rancher desktop.

## Services

To set up the services, copy the required `.env*` files from the `sample_dotenv/` folder into the project root directory. Subsequently, customize each copy as described below. Complete the directory paths in the `.env` file (copy of `sample_dotenv/.env`). Relative paths should start with `./` to avoid being mistaken for a volume name. The current working directory `.` when issuing `docker compose` commands must be the root directory (containing this `README.md`). For development work, at a minimum run the frontend, backend, scheduler, TiTiler, and MinIO.

### `.env.web.be` (backend)

Aside from the self-explanatory settings...

Insert the IPv4 address of your dev machine in the value of `INITIAL_S3_ENDPOINT` before the port number.

Set `JOB_SECRET_ENCRYPTION_KEY` to the base64-encoded representation of random 256-bit key values which you can obtain as follows:
```
head </dev/random -c32 | base64
```
This key encrypts secrets required by jobs.

Set `BUCKET_DETAILS_ENCRYPTION_KEY` to the base64-encoded representation of random 256-bit key values which you can obtain as follows:
```
head </dev/random -c32 | base64
```
This key encrypts bucket credentials.

Need a public/private keypair. Tokens are signed with the private key by the backend, and can be verified with the public key. This is useful for example for the gateway for interactive containers: the gateway simply verifies the token via the public key as obtained via the `GET` method at `https://accelerator-api.iiasa.ac.at/docs#/.well-known/jwks.json`.

Use OpenSSL to generate the keypair and extract the public key:
```
openssl ecparam -genkey -name prime256v1 -noout -out private_key.pem
openssl ec -in private_key.pem -pubout -out public_key.pem
```

Set the following:
```
JWT_BASE64_PRIVATE_KEY="$(base64 -w0 private_key.pem)"
JWT_BASE64_PUBLIC_KEY="$(base64 -w0 public_key.pem)"
```
### `.env.web.fe` (frontend)

Settings are self-explanatory.

### `.env.scheduler` (job dispatcher)

1. In `.env.scheduler` change `IMAGE_REGISTRY_URL=registry:8443`, `IMAGE_REGISTRY_USER=myregistry`, `IMAGE_REGISTRY_PASSWORD=myregistrypassword`
   - When the registry service is running, you can login to it via `docker login registry:8443` and the above username and password.
2. Convert `~/.kube/config` to JSON and then a base64 string:
   ```
   kubectl config view --output json --raw >kubeconfig.json
   ```
   Edit the JSON to remove irrevelant contexts / credentials.
   ```
   base64 -w0 kubeconfig.json >kubeconfig.b64
   ```
3. Set  `WKUBE_SECRET_JSON_B64` to the content of `kubeconfig.b64`.
4. Or use command `python3 -c "import sys, yaml, json; print(json.dumps(yaml.safe_load(sys.stdin), indent=2))" < ~/.kube/config > config.json` to convert the kubernetes config to JSON.

### [TiTiler](https://developmentseed.org/titiler/) (tile server)

See [this issue](https://github.com/iiasa/accelerator_service/issues/58)

1. Clone the repo `https://github.com/developmentseed/titiler`
2. Create a self-signed certificate expiring in `$DAYS` for TiTiler by issuing:
   ```
   cd titiler
   mkdir certs
   cd certs
   openssl req -x509 -newkey rsa:2048 -keyout private.key -out public.crt -days $DAYS -nodes -subj "/CN=localip"
   cp public.cert ../dockerfiles/minio-cert.crt
   cd ..
   ```
3. Copy and adapt the `Dockerfile` for Uvicorn
   ```
   cd dockerfiles
   cp Dockerfile Dockerfile.uvicorn
   # Edit Dockerfile.uvicorn
   cd ..
   ```
4. Build the container:
   ```
   docker build -f dockerfiles/Dockerfile.uvicorn .
   ```

### MinIO (block storage, S3)

1. Create a self-signed certificate:
   ```
   cd minio_certs
   openssl req -x509 -newkey rsa:2048 -keyout private.key -out public.crt -days $DAYS -nodes -subj "/CN=localip"
   cd -
   ```
   where `$DAYS` is the number of days before the certificate expires. Use a big number to effectively have no expiry.
2. Start the service:
   ```
   docker compose -f docker-compose.dev.yml up minio [--build]
   ```
   Optionally use the `--build` flag to allow image to be built if needed.
   containers so as to pick up code changes, updated dependencies, and any
   modifications to the build specification (`Dockefile`).
3. Access MinIO via `https:localhost:9001` and create access key (user ID)
   and matching secret key (password) credentials.
4. In `.env.web.be` and `.env.scheduler`, set these as values of the `*_S3_API_KEY=`
   and `*_S3_SECRET_KEY=` entries.

### Registry

Generate `htpasswd` file:
1. `docker pull httpd:2`
2. `docker run --rm --entrypoint htpasswd httpd:2 -Bbn myregistry myregistrypassword > registry_auth/htpasswd`

### Database

1. Execute `docker compose -f docker-compose.dev.yml up db --build` to start the service and optionally (re)build the image.
2. Enter the db container with `docker exec -it <db container ID> /bin/bash`
3. Create databases inside the container with:
   - `su -- postgres -c "createdb accelerator"`
   - `su -- postgres -c "createdb acceleratortest"`
   - `su -- postgres -c "createdb accms"`

## Miscellaneous

Create local IP entries in your `/etc/hosts`
```
# Accelerator
xxx.xxx.xxx.xxx localip registry web_be
```
where `xxx.xxx.xxx.xxx` is your IP address on the IIASA network.

When changing the network environment, for example by taking a dev laptop home, need to change this.

## Startup the project

`docker compose -f docker-compose.dev.yml up --build`

## Browse

Browse to the backend at `https://localhost:8000`. In case of a security warning on account of the self-signed certificate, add an exception in your browser.

Browse to the frontend at `https://localhost:8080`. In case of a security warning on account of the self-signed certificate, add an exception in your browser. Then log in via the `Login with IIASA` button. To grant yourself administrator rights when logged in do:
```
docker ps | grep web_be
```
Make note of the backend container ID, then shell into the running container and grant:
```
docker exec -it <container ID> /bin/bash
python apply.py add_role <your IIASA email> APP__SUPERUSER
```

## `NOTE`

Inside `control_services_backend` ignore the `.env.sample`, the configs are passed down as the containers are orchestrated.
