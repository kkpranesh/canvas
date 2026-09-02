# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# Be sure to restart your server when you modify this file.

require_relative "../../app/models/setting"

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
begin
  secret = Setting.get("session_secret_key", SecureRandom.hex(64), set_if_nx: true)
rescue
  # The database may not exist yet
  secret = SecureRandom.hex(64)
end

base_config = {
  key: "_normandy_session",
  secret:
}
# Only use same_site :none in environments where we can use secure cookies, as browsers otherwise don't accept it
#
# Also enabled when SIS_EMBED_FRAME_ANCESTORS is set (see
# config/initializers/sis_embed_csp.rb): a session cookie without
# SameSite=None is never even attempted by the browser on requests made
# from inside a cross-origin iframe (the external SIS embedding Canvas),
# regardless of any third-party-cookie-blocking policy — so this is
# required, not optional, for that embedding to work at all. Requires
# Canvas to be served over HTTPS, since Secure cookies are dropped
# outright over plain HTTP.
if Rails.application.config.force_ssl || ENV["SIS_EMBED_FRAME_ANCESTORS"].present?
  base_config[:same_site] = :none
  base_config[:secure] = true
end
config = base_config.merge((Canvas.load_config_from_consul("session_store", failsafe_cache: true) || {}).symbolize_keys)

# :expire_after is the "true" option, and :expires is a legacy option, but is applied
# to the cookie after :expire_after is, so by setting it to nil, we force the lesser
# of session expiration or expire_after
config[:expire_after] ||= 1.day
config[:expires] = nil
config[:logger] = Rails.logger

Autoextend.hook(:EncryptedCookieStore, :SessionsTimeout)

CanvasRails::Application.config.session_store(:enhanced_cookie_store, **config)
CanvasRails::Application.config.secret_token = config[:secret]
