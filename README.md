# API Gateway

Este repositorio contiene un API Gateway basado en `nginx` que expone una unica entrada publica para el frontend en Angular y redirige las solicitudes hacia los microservicios internos del sistema.

Su objetivo principal es:

- centralizar el acceso HTTP desde el frontend;
- ocultar las direcciones internas de los microservicios;
- mantener una configuracion de enrutamiento simple entre cliente y backend;
- actuar como punto de entrada comun para despliegues locales o en contenedores.

## Arquitectura

El frontend Angular consume este gateway en lugar de llamar directamente a cada microservicio. `nginx` recibe las peticiones en el puerto `80` y las reenvia segun la ruta configurada en [default.conf](C:/Users/marti/Desktop/fullstack3/api_gw/default.conf:1).

Servicios actualmente enroutados:

- `ms_auth` en `3000`
- `ms_asistencia` en `3001`
- `ms_comunicaciones` en `3002`
- `ms_gestion` en `8080`

## Requisitos

Para instalar y usar este gateway necesitas lo siguiente.

### Opcion 1: ejecucion con Docker

- Docker instalado
- Docker Compose o una red Docker ya creada donde vivan los microservicios
- Los contenedores `ms_auth`, `ms_asistencia`, `ms_comunicaciones` y `ms_gestion` conectados a la misma red que el gateway

### Opcion 2: instalacion manual con nginx

- `nginx` instalado en el host
- Acceso para modificar la configuracion de `nginx`
- Conectividad de red hacia los microservicios
- Los hostnames o IPs de cada microservicio correctamente resueltos desde la maquina donde corre `nginx`

## Estructura del repositorio

- [Dockerfile](C:/Users/marti/Desktop/fullstack3/api_gw/Dockerfile:1): construye la imagen del gateway
- [default.conf](C:/Users/marti/Desktop/fullstack3/api_gw/default.conf:1): reglas de enrutamiento principales
- [proxy-headers.conf](C:/Users/marti/Desktop/fullstack3/api_gw/proxy-headers.conf:1): cabeceras reenviadas al backend

## Instalacion con Docker

Esta es la forma recomendada para desarrollo y despliegues simples.

### 1. Construir la imagen

```bash
docker build -t api_gw .
```

### 2. Verificar o crear la red Docker

El gateway y los microservicios deben compartir la misma red.

Ejemplo:

```bash
docker network create devops_default
```

Si la red ya existe, no hace falta crearla nuevamente.

### 3. Ejecutar el contenedor

```bash
docker run -d --name api_gw -p 80:80 --network devops_default api_gw
```

Con esto, el gateway quedara disponible en:

```text
http://localhost
```

## Instalacion manual con nginx

Si no vas a usar Docker, puedes instalar la configuracion directamente sobre una instancia de `nginx`.

### 1. Instalar nginx

Instala `nginx` usando el mecanismo habitual de tu sistema operativo.

### 2. Copiar la configuracion

Copia estos archivos:

- [default.conf](C:/Users/marti/Desktop/fullstack3/api_gw/default.conf:1)
- [proxy-headers.conf](C:/Users/marti/Desktop/fullstack3/api_gw/proxy-headers.conf:1)

Un ejemplo comun en Linux seria:

```bash
sudo cp default.conf /etc/nginx/conf.d/default.conf
sudo cp proxy-headers.conf /etc/nginx/conf.d/proxy-headers.conf
```

### 3. Ajustar los destinos si corresponde

En [default.conf](C:/Users/marti/Desktop/fullstack3/api_gw/default.conf:1) puedes usar:

- `localhost` si estas desarrollando un microservicio fuera de Docker;
- el nombre del contenedor si el microservicio corre dentro de la misma red Docker;
- una IP o hostname alcanzable desde el servidor.

Ejemplo:

```nginx
proxy_pass http://ms_auth:3000;
```

o bien:

```nginx
proxy_pass http://localhost:3000;
```

### 4. Validar la configuracion

```bash
nginx -t
```

### 5. Reiniciar o recargar nginx

```bash
sudo systemctl reload nginx
```

## Uso

Una vez levantado, el frontend Angular debe consumir este gateway como base URL de su API. En vez de llamar directamente a cada microservicio, debe apuntar a algo como:

```text
http://localhost/api/...
```

Ejemplos:

- `http://localhost/api/auth/login`
- `http://localhost/api/asistencia`
- `http://localhost/api/mensajes`
- `http://localhost/api/usuarios`

## Rutas publicadas

Actualmente el gateway expone estas rutas principales:

### `ms_auth`

- `/api/auth/`
- `/api/teachers/me/dashboard`
- `/api/students/me/dashboard`
- `/api/admin/me/dashboard`

### `ms_asistencia`

- `/api/anotaciones`
- `/api/asistencia`
- `/api/docentes/cursos`
- `/api/cursos/{id}/alumnos`

### `ms_comunicaciones`

- `/api/mensajes`

### `ms_gestion`

- `/api/academico`
- `/api/docentes`
- `/api/estudiantes`
- `/api/evaluaciones`
- `/api/notas`
- `/api/usuarios`

## Cabeceras reenviadas

El gateway reenvia informacion util al backend mediante [proxy-headers.conf](C:/Users/marti/Desktop/fullstack3/api_gw/proxy-headers.conf:1), incluyendo:

- `Host`
- `X-Real-IP`
- `X-Forwarded-For`
- `X-Forwarded-Proto`
- `Authorization`

Esto permite que los microservicios conserven informacion del cliente original y del token enviado por el frontend.

## Comportamiento ante caida de servicios

Si un microservicio no esta disponible, `nginx` no se cae por completo. Solo fallaran las rutas asociadas a ese servicio y el resto del gateway seguira respondiendo mientras sus backends esten sanos.

En ese caso, es normal recibir respuestas como:

- `502 Bad Gateway`
- `504 Gateway Timeout`

## Verificacion basica

Puedes comprobar que el gateway responde con herramientas como `curl`:

```bash
curl http://localhost/api/auth/
```

O revisar el estado del contenedor:

```bash
docker ps
docker logs api_gw
```

## Problemas comunes

### `502 Bad Gateway`

Posibles causas:

- el microservicio destino no esta levantado;
- el nombre del host configurado en `proxy_pass` no existe en la red;
- el puerto configurado no coincide con el puerto real del servicio.

### El frontend no conecta

Revisa:

- que el gateway este expuesto en el puerto esperado;
- que Angular este apuntando a la URL correcta;
- que no exista un firewall bloqueando el acceso;
- que los microservicios compartan red con el gateway si usas Docker.

### `nginx -t` falla

Revisa errores de sintaxis o rutas incorrectas en los archivos `.conf`.

## Recomendaciones de instalacion

- Mantener este gateway y los microservicios dentro de una misma red privada
- Versionar cualquier cambio en [default.conf](C:/Users/marti/Desktop/fullstack3/api_gw/default.conf:1)
- Probar conectividad entre gateway y servicios antes de exponer el frontend
- Ajustar `proxy_pass` segun el entorno: local, Docker o servidor remoto

## Comando de referencia

Comandos usados habitualmente en este proyecto:

```bash
docker build -t api_gw .
docker run -d --name api_gw -p 80:80 --network devops_default api_gw
```
