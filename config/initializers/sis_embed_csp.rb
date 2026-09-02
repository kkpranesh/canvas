# frozen_string_literal: true

# Allows a trusted external SIS application to iframe ordinary Canvas pages
# (not just LTI tool launches) inside its own UI.
#
# Stock Canvas removes the default X-Frame-Options header globally
# (config/application.rb), but ApplicationController#set_response_headers
# still sets its own dynamic Content-Security-Policy
# "frame-ancestors 'self' <account's own vanity domains>" on every ordinary
# page — see ApplicationController#csp_frame_ancestors, whose only
# extension points (`<<`, Lti::Concerns::ParentFrame) are hardcoded to
# trusted *internal* LTI tool contexts (e.g. New Quizzes), not arbitrary
# external origins. There is no admin-facing setting for this, so this
# small, additive prepend is the only way to add a trusted external origin.
#
# Config-driven and purely additive: SIS_EMBED_FRAME_ANCESTORS is a
# space-separated list of trusted origins (e.g. the SIS frontend's own
# origin, https://sis.example.com). Unset/blank means zero change from
# stock Canvas behavior. This file is fully self-contained and can be
# deleted at any time to revert to stock behavior.
module SisEmbedCsp
  def csp_frame_ancestors
    extra_origins = ENV["SIS_EMBED_FRAME_ANCESTORS"].to_s.split
    super.concat(extra_origins)
  end
end

if ENV["SIS_EMBED_FRAME_ANCESTORS"].present?
  ApplicationController.prepend(SisEmbedCsp)
end
