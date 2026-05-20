FROM nginx:alpine

COPY default.conf /etc/nginx/conf.d/default.conf
COPY proxy-headers.conf /etc/nginx/conf.d/proxy-headers.conf

EXPOSE 80
