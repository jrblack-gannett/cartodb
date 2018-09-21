require 'spec_helper_min'
require 'carto/oauth_provider/scopes'

describe Carto::OauthProvider::Scopes do

  describe '#invalid_scopes' do
    include Carto::OauthProvider::Scopes
    before :all do
      @user = FactoryGirl.create(:carto_user)
    end

    after :all do
      @user.destroy
    end

    it 'validates supported scopes' do
      scopes = Carto::OauthProvider::Scopes.invalid_scopes(Carto::OauthProvider::Scopes::SUPPORTED_SCOPES, @user)
      expect(scopes).to be_empty
    end

    it 'returns non existent datasets scopes' do
      scopes = Carto::OauthProvider::Scopes.invalid_scopes(['datasets:r:wtf'], @user)
      expect(scopes).to eq(['datasets:r:wtf'])
    end

    it 'validates existing datasets scopes' do
      user_table = FactoryGirl.create(:carto_user_table, :with_db_table, user_id: @user.id)
      scopes = Carto::OauthProvider::Scopes.invalid_scopes(["datasets:r:#{user_table.name}"], @user)
      expect(scopes).to be_empty
      user_table.destroy
    end
  end

  describe Carto::OauthProvider::Scopes::DataservicesScope do
    describe '#add_to_api_key_grants' do
      let(:scope) { Carto::OauthProvider::Scopes::DataservicesScope.new('geocoding', 'GC') }

      it 'adds SQL api and dataservice' do
        grants = [{ type: 'apis', apis: [] }]
        scope.add_to_api_key_grants(grants)
        expect(grants).to(eq([{ type: 'apis', apis: ['sql'] }, { type: 'dataservices', services: ['geocoding'] }]))
      end

      it 'does not add duplicate SQL api' do
        grants = [{ type: 'apis', apis: ['sql'] }]
        scope.add_to_api_key_grants(grants)
        expect(grants).to(include(type: 'apis', apis: ['sql']))
      end
    end
  end

  describe Carto::OauthProvider::Scopes::UserScope do
    describe '#add_to_api_key_grants' do
      let(:scope) { Carto::OauthProvider::Scopes::UserScope.new('profile', 'User public profile') }

      it 'adds user scope with profile subset' do
        grants = [{ type: 'apis', apis: [] }]
        scope.add_to_api_key_grants(grants)
        expect(grants).to(eq([{ type: 'apis', apis: [] }, { type: 'user', data: ['profile'] }]))
      end
    end
  end

  describe Carto::OauthProvider::Scopes::DatasetsScope do
    describe '#add_to_api_key_grants' do
      let(:full_scope) { Carto::OauthProvider::Scopes::DatasetsScope.new('rw', 'untitled_table') }
      let(:read_scope) { Carto::OauthProvider::Scopes::DatasetsScope.new('r', 'untitled_table') }
      let(:write_scope) { Carto::OauthProvider::Scopes::DatasetsScope.new('w', 'untitled_table') }
      let(:full_table_grants) do
        [
          {
            apis: [
              'maps',
              'sql'
            ],
            type: 'apis'
          },
          {
            tables: [
              {
                name: 'untitled_table',
                permissions: [
                  'select',
                  'insert',
                  'update',
                  'delete'
                ],
                schema: 'wadus'
              }
            ],
            type: 'database'
          }
        ]
      end
      let(:read_table_grants) do
        [
          {
            apis: [
              'maps',
              'sql'
            ],
            type: 'apis'
          },
          {
            tables: [
              {
                name: 'untitled_table',
                permissions: [
                  'select'
                ],
                schema: 'wadus'
              }
            ],
            type: 'database'
          }
        ]
      end
      let(:write_table_grants) do
        [
          {
            apis: [
              'maps',
              'sql'
            ],
            type: 'apis'
          },
          {
            tables: [
              {
                name: 'untitled_table',
                permissions: [
                  'insert',
                  'update',
                  'delete'
                ],
                schema: 'wadus'
              }
            ],
            type: 'database'
          }
        ]
      end

      it 'adds full access permissions' do
        grants = [{ type: 'apis', apis: [] }]
        full_scope.add_to_api_key_grants(grants, 'wadus')
        expect(grants).to(eq(full_table_grants))
      end

      it 'does not add write permissions' do
        grants = [{ type: 'apis', apis: [] }]
        read_scope.add_to_api_key_grants(grants, 'wadus')
        expect(grants).to(eq(read_table_grants))
      end

      it 'does not add read permissions' do
        grants = [{ type: 'apis', apis: [] }]
        write_scope.add_to_api_key_grants(grants, 'wadus')
        expect(grants).to(eq(write_table_grants))
      end
    end
  end
end
