para dockerizarlo:
`docker build -t api_gw .`

para ejecutar el contenedor:
`docker run -d --name api_gw -p 80:80 --network devops_default api_gw`
