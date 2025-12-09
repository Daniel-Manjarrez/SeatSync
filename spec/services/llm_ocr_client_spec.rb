require 'rails_helper'

RSpec.describe LlmOcrClient do
  let(:fake_client) { double('OpenAI::Client') }
  let(:temp_image_path) { Rails.root.join('spec/fixtures/files/sample_receipt.jpg') }

  # Mock ENV variables for all tests to avoid dependency on .env file
  before(:each) do
    allow(ENV).to receive(:fetch).with('AZURE_OPENAI_ENDPOINT').and_return('https://test.openai.azure.com/')
    allow(ENV).to receive(:fetch).with('AZURE_OPENAI_API_KEY').and_return('test-key')
    allow(ENV).to receive(:fetch).with('AZURE_OPENAI_CHAT_DEPLOYMENT').and_return('gpt-4')
    allow(ENV).to receive(:fetch).with('AZURE_OPENAI_API_VERSION').and_return('2024-02-15-preview')
  end

  describe '#initialize' do
    it 'accepts a custom client' do
      client = LlmOcrClient.new(client: fake_client)
      expect(client.instance_variable_get(:@client)).to eq(fake_client)
    end

    it 'builds a default client when none provided' do
      # Mock OpenAI::Client.new to avoid creating real client
      allow(OpenAI::Client).to receive(:new).and_return(fake_client)

      client = LlmOcrClient.new
      expect(client.instance_variable_get(:@client)).to eq(fake_client)
    end
  end

  describe '#extract_text' do
    let(:client) { LlmOcrClient.new(client: fake_client) }

    context 'when successful' do
      before do
        allow(fake_client).to receive(:chat).and_return(
          'choices' => [
            {
              'message' => {
                'content' => "Receipt Text\n01/15/2025\nBurger $10.00\nTotal $10.00"
              }
            }
          ]
        )
      end

      it 'extracts text from image' do
        result = client.extract_text(temp_image_path.to_s)
        expect(result).to include('Receipt Text')
        expect(result).to include('Burger')
      end

      it 'sends correct parameters to OpenAI client' do
        expect(fake_client).to receive(:chat).with(
          hash_including(
            parameters: hash_including(
              temperature: 0,
              max_tokens: 2000
            )
          )
        ).and_return(
          'choices' => [{ 'message' => { 'content' => 'test' } }]
        )

        client.extract_text(temp_image_path.to_s)
      end

      it 'includes system message for OCR assistant' do
        expect(fake_client).to receive(:chat).with(
          hash_including(
            parameters: hash_including(
              messages: array_including(
                hash_including(
                  role: 'system',
                  content: /receipt OCR assistant/
                )
              )
            )
          )
        ).and_return(
          'choices' => [{ 'message' => { 'content' => 'test' } }]
        )

        client.extract_text(temp_image_path.to_s)
      end

      it 'sends base64-encoded image' do
        expect(fake_client).to receive(:chat).with(
          hash_including(
            parameters: hash_including(
              messages: array_including(
                hash_including(
                  content: array_including(
                    hash_including(
                      type: 'image_url',
                      image_url: hash_including(
                        url: /data:image\/png;base64,/
                      )
                    )
                  )
                )
              )
            )
          )
        ).and_return(
          'choices' => [{ 'message' => { 'content' => 'test' } }]
        )

        client.extract_text(temp_image_path.to_s)
      end
    end

    context 'when response uses symbol keys' do
      before do
        allow(fake_client).to receive(:chat).and_return(
          choices: [
            {
              message: {
                content: "Receipt with symbols"
              }
            }
          ]
        )
      end

      it 'handles symbol keys correctly' do
        result = client.extract_text(temp_image_path.to_s)
        expect(result).to eq("Receipt with symbols")
      end
    end

    context 'when response is empty' do
      before do
        allow(fake_client).to receive(:chat).and_return(
          'choices' => [{ 'message' => { 'content' => '' } }]
        )
      end

      it 'raises an error for empty content' do
        expect {
          client.extract_text(temp_image_path.to_s)
        }.to raise_error(RuntimeError, /Empty LLM OCR response/)
      end
    end

    context 'when response is nil' do
      before do
        allow(fake_client).to receive(:chat).and_return(
          'choices' => [{ 'message' => { 'content' => nil } }]
        )
      end

      it 'raises an error for nil content' do
        expect {
          client.extract_text(temp_image_path.to_s)
        }.to raise_error(RuntimeError, /Empty LLM OCR response/)
      end
    end

    context 'when response has only whitespace' do
      before do
        allow(fake_client).to receive(:chat).and_return(
          'choices' => [{ 'message' => { 'content' => "   \n  \t  " } }]
        )
      end

      it 'raises an error for whitespace-only content' do
        expect {
          client.extract_text(temp_image_path.to_s)
        }.to raise_error(RuntimeError, /Empty LLM OCR response/)
      end
    end

    context 'when API call fails' do
      before do
        allow(fake_client).to receive(:chat).and_raise(StandardError.new('API Error'))
      end

      it 'propagates the error' do
        expect {
          client.extract_text(temp_image_path.to_s)
        }.to raise_error(StandardError, /API Error/)
      end
    end
  end

  describe '#build_client' do
    it 'builds an OpenAI client with correct parameters' do
      mock_openai_client = double('OpenAI::Client')

      # Expect exactly one call when build_client is invoked
      expect(OpenAI::Client).to receive(:new).once.with(
        hash_including(
          access_token: 'test-key',
          api_type: :azure,
          api_version: '2024-02-15-preview',
          request_timeout: LlmOcrClient::DEFAULT_TIMEOUT,
          max_retries: LlmOcrClient::DEFAULT_MAX_RETRIES
        )
      ).and_return(mock_openai_client)

      # Create client with mocked client to avoid calling build_client in initialize
      client = LlmOcrClient.new(client: fake_client)
      # Now explicitly call build_client
      openai_client = client.send(:build_client)

      expect(openai_client).to eq(mock_openai_client)
    end

    it 'strips trailing slash from endpoint' do
      # Override ENV mock for this test
      allow(ENV).to receive(:fetch).with('AZURE_OPENAI_ENDPOINT').and_return('https://test.openai.azure.com/')

      mock_openai_client = double('OpenAI::Client')
      expect(OpenAI::Client).to receive(:new).once.with(
        hash_including(
          uri_base: 'https://test.openai.azure.com/openai/deployments/gpt-4'
        )
      ).and_return(mock_openai_client)

      client = LlmOcrClient.new(client: fake_client)
      client.send(:build_client)
    end

    it 'constructs correct uri_base' do
      mock_openai_client = double('OpenAI::Client')
      expect(OpenAI::Client).to receive(:new).once.with(
        hash_including(
          uri_base: 'https://test.openai.azure.com/openai/deployments/gpt-4'
        )
      ).and_return(mock_openai_client)

      client = LlmOcrClient.new(client: fake_client)
      client.send(:build_client)
    end

    it 'uses correct timeout and retry settings' do
      mock_openai_client = double('OpenAI::Client')
      expect(OpenAI::Client).to receive(:new).once.with(
        hash_including(
          request_timeout: LlmOcrClient::DEFAULT_TIMEOUT,
          max_retries: LlmOcrClient::DEFAULT_MAX_RETRIES
        )
      ).and_return(mock_openai_client)

      client = LlmOcrClient.new(client: fake_client)
      client.send(:build_client)
    end
  end
end
