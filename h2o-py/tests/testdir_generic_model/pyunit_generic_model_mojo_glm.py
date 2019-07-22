import h2o
import tempfile
import os
from h2o.estimators import H2OGeneralizedLinearEstimator, H2OGenericEstimator
from tests import pyunit_utils
from tests.testdir_generic_model import compare_output, Capturing

def test(x, y, output_test, strip_part, algo_name, generic_algo_name):

    # GLM
    airlines = h2o.import_file(path=pyunit_utils.locate("smalldata/testng/airlines_train.csv"))
    glm = H2OGeneralizedLinearEstimator(nfolds = 3, family = "binomial")
    glm.train(x = x, y = y, training_frame=airlines, validation_frame=airlines, )
    print(glm)
    with Capturing() as original_output:
        glm.show()
    original_model_filename = "/home/pavel/mojo_glm_test.zip"
    original_model_filename = glm.download_mojo(original_model_filename)
      
    model = H2OGenericEstimator.from_file(original_model_filename)
    assert model is not None
    print(model)
    with Capturing() as generic_output:
        model.show()
    output_test(str(original_output), str(generic_output), strip_part, algo_name, generic_algo_name)
    predictions = model.predict(airlines)
    assert predictions is not None
    assert predictions.nrows == 24421
    assert model._model_json["output"]["model_summary"] is not None
    assert len(model._model_json["output"]["model_summary"]._cell_values) > 0

    generic_mojo_filename = tempfile.mkdtemp("zip", "genericMojo");
    generic_mojo_filename = model.download_mojo(path=generic_mojo_filename)
    assert os.path.getsize(generic_mojo_filename) == os.path.getsize(original_model_filename)

def mojo_model_test_binomial():
    test(["Origin", "Dest"], "IsDepDelayed", compare_output, 'GLM Model: summary','ModelMetricsBinomialGLM: glm', 'ModelMetricsBinomialGLMGeneric: generic')
    
if __name__ == "__main__":
    pyunit_utils.standalone_test(mojo_model_test_binomial)
else:
    mojo_model_test_binomial()
