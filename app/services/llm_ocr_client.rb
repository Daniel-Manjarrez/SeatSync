require 'openai'
require 'base64'

class LlmOcrClient
  DEFAULT_TIMEOUT = 120
  DEFAULT_MAX_RETRIES = 2

  def initialize(client: nil)
    @client = client || build_client
  end

  def extract_text(image_path)
    base64_image = Base64.strict_encode64(File.binread(image_path))

    response = @client.chat(
      parameters: {
        messages: [
          {
            role: 'system',
            content: 'You are a receipt OCR assistant. Return only the plain text visible on the receipt without commentary.'
          },
          {
            role: 'user',
            content: [
              { type: 'text', text: 'Extract all text from this receipt image. Return only the raw receipt text as a single string.' },
              { type: 'image_url', image_url: { url: "data:image/png;base64,#{base64_image}" } }
            ]
          }
        ],
        temperature: 0,
        max_tokens: 2000
      }
    )

    content = response.dig('choices', 0, 'message', 'content') || response.dig(:choices, 0, :message, :content)
    raise 'Empty LLM OCR response' if content.nil? || content.strip.empty?

    Rails.logger&.warn("LLM OCR content (truncated): #{content.strip[0, 1000]}")

    content
  end

  private

  def build_client
    base = ENV.fetch('AZURE_OPENAI_ENDPOINT').chomp('/')
    deployment = ENV.fetch('AZURE_OPENAI_CHAT_DEPLOYMENT')

    OpenAI::Client.new(
      access_token: ENV.fetch('AZURE_OPENAI_API_KEY'),
      uri_base: "#{base}/openai/deployments/#{deployment}",
      api_type: :azure,
      api_version: ENV.fetch('AZURE_OPENAI_API_VERSION'),
      request_timeout: DEFAULT_TIMEOUT,
      max_retries: DEFAULT_MAX_RETRIES
    )
  end
end
