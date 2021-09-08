VERSION := $(shell sh -c 'cat VERSION')

clean_pkg: 
	@rm -rf pkg/* docker/*.gem 

clean_gems:
	@rm -rf docker/gem/* docker/gems/*

clean: clean_pkg clean_gems
	@rm -rf docker/licenses

build: clean_pkg 
	@bundle exec rake build

docker: build install-deps
	@cp pkg/fluent-plugin-*.gem docker
	@mkdir -p docker/licenses
	@cp -rp LICENSE docker/licenses/
	@docker context create tls-environment
	@docker context ls
	@docker buildx create --name mybuilder --use tls-environment 
	@docker buildx inspect --bootstrap
	@docker login -u ${USERNAME} -p ${PASSWORD}
	@docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	@docker buildx build --build-arg VERSION=$(VERSION) -t odidev/k8s-metrics-agggr:$(VERSION) --platform linux/amd64,linux/arm64 --push ./docker
	@docker buildx rm mybuilder
unit-test: 
	@bundle exec rake test

install-deps:
	@gem install bundler
	@bundle update --bundler
	@bundle install

unpack: build
	@cp pkg/fluent-plugin-*.gem docker
	@mkdir -p docker/gem
	@rm -rf docker/gem
	@gem unpack docker/fluent-plugin-*.gem --target docker/gem
	@cd docker && bundle install
