FROM swift:latest as builder
ENV HTTP_PROXY=http://172.20.0.1:7890 HTTPS_PROXY=http://172.20.0.1:7890 ALL_PROXY=socks5://172.20.0.1:7890
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/src/.build \
    swift build -c release && cp -af .build/release/ /src/release/

FROM swift:slim
ENV TZ=Asia/Shanghai
WORKDIR /root
COPY --from=builder /src/release .
EXPOSE 8000
CMD ["./ControlCenter", "-p", "53214", "--db-config", "/etc/ControlCenter/database.config", "--important-info-service-config", "/etc/ControlCenter/important_info_service.config"]
