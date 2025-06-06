build:
	docker build --no-cache --platform="linux/x86_64" -t nestorrente/k8s-simple-app-drone:v0.1.0 .

tag:
	docker tag nestorrente/k8s-simple-app-drone:v0.1.0 nestorrente/k8s-simple-app-drone:v0.1.0-snapshot

push:
	docker push nestorrente/k8s-simple-app-drone:v0.1.0-snapshot

deploy:
	make build
	make tag
	make push
