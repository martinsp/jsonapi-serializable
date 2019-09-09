require 'spec_helper'

describe JSONAPI::Serializable::Resource do
  let(:klass) do
    Class.new(JSONAPI::Serializable::Resource) do
      type 'foo'
      id { 'bar' }
    end
  end

  let(:object) do
    User.new(posts: [Post.new(id: 1)])
  end

  let(:resource) { klass.new(object: object) }

  subject { resource.as_jsonapi }

  context 'when keys are formatted' do
    let(:resource) do
      klass.new(object: object, _class: { Post: SerializablePost })
    end

    before do
      klass.class_eval do
        extend JSONAPI::Serializable::Resource::KeyFormat
        key_format ->(k) { k.to_s.capitalize }
        attribute :name
        attribute :address
        relationship :posts
        belongs_to :author
        has_many :comments
        has_one :review
      end
    end

    expected = {
      type: :foo,
      id: 'bar',
      attributes: { Name: nil, Address: nil },
      relationships: {
        Posts: {
          meta: { included: false }
        },
        Author: {
          meta: { included: false }
        },
        Comments: {
          meta: { included: false }
        },
        Review: {
          meta: { included: false }
        }
      }
    }

    it { is_expected.to eq(expected) }

    context 'when fields are specified' do
      subject { resource.as_jsonapi(fields: [:name, :address, :posts, :author, :comments, :review]) }
      it { is_expected.to eq(expected) }
    end

    context 'when fields are specified with transformed keys' do
      subject { resource.as_jsonapi(fields: [:Name, :Address, :Posts, :Author, :Comments, :Review]) }
      it { is_expected.to eq(expected) }
    end

    context 'whith included relationships' do
      expected_with_relationships = {
        type: :foo,
        id: 'bar',
        attributes: { Name: nil, Address: nil },
        relationships: {
          Posts: {
            data: [
              {
                id: '1',
                type: :posts
              }
            ]
          },
          Author: {
            meta: { included: false }
          },
          Comments: {
            meta: { included: false }
          },
          Review: {
            meta: { included: false }
          }
        }
      }
      subject { resource.as_jsonapi(include: [:posts]) }
      it { is_expected.to eq(expected_with_relationships) }
    end

    context 'when inheriting' do
      let(:subclass) { Class.new(klass) }
      let(:resource) { subclass.new(object: object) }

      it { is_expected.to eq(expected) }
    end
  end

  context 'when KeyFormat is prepended' do
    it 'outputs a deprecation warning' do
      expect { klass.prepend JSONAPI::Serializable::Resource::KeyFormat }
        .to output(/DERPRECATION WARNING/).to_stderr
    end
  end
end
