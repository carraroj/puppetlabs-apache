# frozen_string_literal: true

require 'spec_helper'

describe 'apache::vhost::proxy' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'myproxy' }

      context 'adding to the default vhost' do
        let(:pre_condition) { 'include apache' }

        let(:params) do
          {
            vhost: 'default',
            port: 80,
            priority: 15
          }
        end

        context 'without any parameters' do
          it { is_expected.to compile.and_raise_error(%r{At least one of}) }
        end

        context 'with proxy_pass' do
          let(:params) do
            super().merge(
              proxy_pass: [
                {
                  path: '/',
                  url: 'http://localhost:8080/'
                },
              ],
            )
          end

          it 'creates a concat fragment' do
            expect(subject).to compile.with_all_deps
            expect(subject).to contain_class('apache::mod::proxy')
            expect(subject).to contain_class('apache::mod::proxy_http')
            expect(subject).to contain_concat('15-default-80.conf')
            expect(subject).to create_concat__fragment('default-myproxy-proxy')
              .with_target('15-default-80.conf')
              .with_order(170)
              .with_content(
                Regexp.new(<<~CONTENT),
                  \n\s\s## Proxy rules
                  \s\sProxyRequests Off
                  \s\sProxyPreserveHost Off
                  \s\sProxyPass / http://localhost:8080/
                  \s\sProxyPassReverse / http://localhost:8080/
                CONTENT
              )
          end

          context 'with HTTP/2 proxy_dest URL' do
            let(:params) do
              super().merge(proxy_dest: 'h2://localhost:8080/')
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('apache::mod::proxy_http2') }
          end

          context 'with HTTP/2 proxy_dest_match URL' do
            let(:params) do
              super().merge(proxy_dest_match: 'h2://localhost:8080/')
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('apache::mod::proxy_http2') }
          end

          context 'with HTTP/2 proxy_pass URL' do
            let(:params) do
              super().merge(
                proxy_pass: [
                  {
                    path: '/',
                    url: 'h2://localhost:8080/'
                  },
                ],
              )
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('apache::mod::proxy_http2') }
          end

          context 'with HTTP/2 proxy_pass_match URL' do
            let(:params) do
              super().merge(
                proxy_pass_match: [
                  {
                    path: '/',
                    url: 'h2://localhost:8080/'
                  },
                ],
              )
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('apache::mod::proxy_http2') }
          end
        end
      end
    end
  end
end
