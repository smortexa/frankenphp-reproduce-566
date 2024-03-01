# frankenphp-reproduce-566
### Prerequisites
- Docker
- Mac with Apple silicon
---
### Steps to reproduce `exit status 139`
> Use official FrankenPHP base image

- Clone this repository
- cd to cloned repository
- Build the image:
```
docker build -t frankentest:3 -f FrankenPHP_3.Dockerfile .
```
- Run the container
```
docker run -p 9003:9003 --rm frankentest:3
```
- You will see:
```
2024-02-29 14:40:25,451 INFO Set uid to user 1000 succeeded
2024-02-29 14:40:25,452 INFO supervisord started with pid 1
2024-02-29 14:40:26,463 INFO spawned: 'octane_00' with pid 20

   INFO  Server running…

  Local: http://0.0.0.0:9003

  Press Ctrl+C to stop the server

2024-02-29 14:40:27,226 WARN exited: octane_00 (exit status 139; not expected)
```
---
### Steps to reproduce `exit status 139`
> Use `php:${PHP_VERSION}-zts-bookworm`

- Clone this repository
- cd to cloned repository
- Build the image:
```
docker build -t frankentest:1 -f FrankenPHP.Dockerfile .
```
- Run the container
```
docker run -p 9003:9003 --rm frankentest:1
```
- You will see:
```
2024-02-29 14:40:25,451 INFO Set uid to user 1000 succeeded
2024-02-29 14:40:25,452 INFO supervisord started with pid 1
2024-02-29 14:40:26,463 INFO spawned: 'octane_00' with pid 20

   INFO  Server running…

  Local: http://0.0.0.0:9003

  Press Ctrl+C to stop the server

2024-02-29 14:40:27,226 WARN exited: octane_00 (exit status 139; not expected)
```
---
### Steps to reproduce `undefined symbol: core_globals_offset`
> Use `php:${PHP_VERSION}-cli-bookworm`

- Clone this repository
- cd to cloned repository
- Build the image:
```
docker build -t frankentest:2 -f FrankenPHP_2.Dockerfile .
```
- Run the container
```
docker run -p 9003:9003 --rm frankentest:2
```
- You will see:
```
2024-02-29 15:06:49,974 INFO spawned: 'octane_00' with pid 36

   WARN  Unable to determine the current FrankenPHP binary version. Please report this issue: https://github.com/laravel/octane/issues/new.

   INFO  Server running…

  Local: http://0.0.0.0:9003

  Press Ctrl+C to stop the server


   INFO  /var/www/html/frankenphp: symbol lookup error: /var/www/html/frankenphp: undefined symbol: core_globals_offset
2024-02-29 15:06:50,712 WARN exited: octane_00 (exit status 127; not expected)

```
---
### Steps to reproduce `error while reading the request body`

- Clone this repository
- cd to cloned repository
- Build the image:
```
docker build -t frankentest:4 -f FrankenPHP_4.Dockerfile .
```
- Run the container
```
docker run -p 9003:9003 --rm frankentest:4
```
- Open `localhost:9003`
- Upload a file through the form
- You will see:
```
2024-03-01 07:44:42,374 INFO spawned: 'octane_00' with pid 20

   INFO  Server running…

  Local: http://0.0.0.0:9003

  Press Ctrl+C to stop the server

2024-03-01 07:44:43,764 INFO success: octane_00 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)

   WARN  unable to get instance ID; storage clean stamps will be incomplete
  200    GET / ...................................................... 280.56 ms
  200    POST /upload ................................................ 42.74 ms

   ERROR  error while reading the request body

```
