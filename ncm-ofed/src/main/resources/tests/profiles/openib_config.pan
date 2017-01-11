object template openib_config;

include 'components/ofed/schema';

bind '/' = component_ofed_openib;
'/hardware/mlx4' = true;
