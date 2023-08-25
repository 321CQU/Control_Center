FROM swift:latest as builder
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/src/.build \
    swift build -c release && cp -af .build/release/ /src/release/

FROM swift:slim
ENV TZ=Asia/Shanghai
WORKDIR /root
COPY --from=builder /src/release .
EXPOSE 8000
CMD ["./ControlCenter", "--debug", "--db-config", "/etc/ControlCenter/database.config", "--important-info-service-config", "/etc/ControlCenter/important_info_service.config"]
