require "spec_helper"
require "openfarm_errors"

describe Api::V1::CropsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before do
    Crop.collection.drop
    FactoryBot.create(:crop, name: "other bean")
    @beans = FactoryBot.create(:crop, name: "mung bean")
    FactoryBot.create_list(:crop, 2)
    Crop.searchkick_index.refresh
  end

  it "lists crops." do
    skip "this test does not pass on CI - RickCarlino"
    Legacy._get self, "index", format: :json, filter: "mung"
    expect(response.status).to eq(200)
    expect(json["data"].length).to eq(1)
    expect(json["data"][0]["id"]).to eq(@beans.id.to_s)
  end

  it "returns [] for tiny searches" do
    SmarfDoc.skip
    Legacy._get self, "index", format: :json, query: "mu"
    expect(response.status).to eq(200)
    expect(json).to eq("data" => [])
  end

  it "should show a crop" do
    crop = FactoryBot.create(:crop)
    Legacy._get self, "show", format: :json, id: crop.id
    expect(response.status).to eq(200)
    expect(json["data"]["attributes"]["name"]).to eq(crop.name)
  end

  it "should not find a crop" do
    Legacy._get self, "show", format: :json, id: 1
    expect(response.status).to eq(404)
    expect(json["errors"][0]["title"]).to include("Not Found.")
  end

  it "should minimally create a crop" do
    sign_in user
    Legacy._post self, :create, data: { attributes: { name: "Radish" } }
    expect(response.status).to eq(200)
    expect(Crop.last.name).to eq("Radish")
  end

  it "should update a crop" do
    sign_in user
    crop = FactoryBot.create(:crop)
    Legacy._put self, :update,
                id: crop.id,
                data: { attributes: { description: "Updated", tags_array: ["tag"] } }
    expect(response.status).to eq(200)
    crop.reload
    expect(crop.description).to eq("Updated")
    expect(crop.tags).to eq("tag")
  end

  it "tests whether tags get added as an array", js: true do
    crop = FactoryBot.create(:crop)
    sign_in user
    Legacy._put self, :update,
                id: crop.id,
                data: { attributes: { tags_array: %w(just some tags) } }
    expect(response.status).to eq(200)
    expect(crop.reload.tags_array.length).to eq(3)
  end

  it "tests whether common names get added as an array", js: true do
    crop = FactoryBot.create(:crop)
    sign_in user
    Legacy._put self, :update,
                id: crop.id,
                data: { attributes: { common_names: ["Radish", "Red Thing", "New"] } }
    expect(response.status).to eq(200)
    expect(crop.reload.common_names.length).to eq(3)
  end

  it "should return an error when updating faulty information" do
    sign_in user
    crop = FactoryBot.create(:crop)
    Legacy._put self, :update, id: crop.id, data: { attributes: { description: "" } }
    expect(response.status).to eq(422)
    old_description = crop.description
    crop.reload
    expect(crop.description).to eq(old_description)
  end

  it "should add a taxon to a crop" do
    crop = FactoryBot.create(:crop)
    sign_in user
    Legacy._put self, :update,
                id: crop.id,
                data: { attributes: { taxon: "Genus" } }
    expect(response.status).to eq(200)
    expect(crop.reload.taxon).to eq("Genus")
  end
end
