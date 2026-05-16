#include <stdio.h>

#include "FLOOD.h"

#include "rng.h"

void do_compute(struct parameters p, struct results &r) {

    double max_spillage_iter = p.threshold + 1;

    int water_level[NROWS*NCOLS];
    float spillage_flag[NROWS*NCOLS];
    float spillage_level[NROWS*NCOLS];
    float spillage_from_neigh[NROWS*NCOLS*CONTIGUOUS_CELLS];
    const float INV_PRECISION = 1.0f / (float)PRECISION;

    int row_pos, col_pos, depth_pos;
    initialization_row:
    for (row_pos = 0; row_pos < NROWS; row_pos++) {
        #pragma HLS PIPELINE II=1
        initialization_col:
        for (col_pos = 0; col_pos < NCOLS; col_pos++) {
            accessMat(water_level, row_pos, col_pos) = 0;
            accessMat(spillage_flag, row_pos, col_pos) = 0.0;
            accessMat(spillage_level, row_pos, col_pos) = 0.0;
            int depths = CONTIGUOUS_CELLS;
            initialization_depth:
            for (depth_pos = 0; depth_pos < depths; depth_pos++) {
                #pragma HLS UNROLL
                accessMat3D(spillage_from_neigh, row_pos, col_pos, depth_pos) = 0.0;
            }    
        }
    }

    /* Flood simulation (time iterations) */
    main_minute_loop:
    for (r.minute = 0; r.minute < p.num_minutes && max_spillage_iter > p.threshold; r.minute++) {
        #pragma HLS loop_tripcount min=0 max=NUM_MIN avg=NUM_MIN
        int new_row, new_col;
        int cell_pos;

        /* Step 1: Clouds movement */
        cloud_movement:
        for (int cloud = 0; cloud < NCLOUDS; cloud++) {
            #pragma HLS PIPELINE II=1
            // Calculate new position (x are rows, y are columns)
            p.clouds[cloud].x += p.clouds[cloud].dx / 60;
            p.clouds[cloud].y += p.clouds[cloud].dy / 60;
        }

        /* Rainfall */
        rainfall_cloud:
        for (int cloud = 0; cloud < NCLOUDS; cloud++) {
            // Compute the bounding box area of the cloud
            float row_start = COORD_SCEN2MAT_Y(MAX(0, p.clouds[cloud].y - p.clouds[cloud].radius));
            float row_end = COORD_SCEN2MAT_Y(MIN(p.clouds[cloud].y + p.clouds[cloud].radius, SCENARIO_SIZE));
            float col_start = COORD_SCEN2MAT_X(MAX(0, p.clouds[cloud].x - p.clouds[cloud].radius));
            float col_end = COORD_SCEN2MAT_X(MIN(p.clouds[cloud].x + p.clouds[cloud].radius, SCENARIO_SIZE));
            float distance;

            // Access all cloud parameters once - to avoid reaccesing inside the loops
            float cloud_x = p.clouds[cloud].x;
            float cloud_y = p.clouds[cloud].y; 
            float radius = p.clouds[cloud].radius;
            float intensity = p.clouds[cloud].intensity;
            float sqrt_intensity = sqrt(intensity);

            // total rain - local variable per cloud 
            int local_total_rain = 0;

            // Add rain to the ground water level
            float row_pos, col_pos;

            rainfall_row:
            for (row_pos = row_start; row_pos < row_end; row_pos++) {
                #pragma HLS loop_tripcount min=0 max=NROWS avg=NROWS
                float y_pos = COORD_MAT2SCEN_Y(row_pos);
                float dy = y_pos - cloud_y;

                rainfall_col:
                for (col_pos = col_start; col_pos < col_end; col_pos++) {
                    #pragma HLS loop_tripcount min=0 max=NCOLS avg=NCOLS
                    #pragma HLS PIPELINE II=1
                    
                    float x_pos = COORD_MAT2SCEN_X(col_pos);
                    
                    distance = sqrt(SQR(x_pos - cloud_x) + SQR(dy));
                    if (distance < radius) {
                        float rain =
                            p.ex_factor * MAX(0, intensity - distance / radius * sqrt_intensity);
                        float meters_per_minute = rain / 1000 / 60;
                        int rain_fixed = FIXED(meters_per_minute);

                        accessMat(water_level, row_pos, col_pos) += rain_fixed;
                        local_total_rain += rain_fixed;
                    }
                }
            }
            r.total_rain += local_total_rain;
        }
       

        /* Step 2: Compute water spillage to neighbor cells */
        spillage_row:
        for (row_pos = 0; row_pos < NROWS; row_pos++) {
            spillage_col:
            for (col_pos = 0; col_pos < NCOLS; col_pos++) {
                #pragma HLS pipeline II=1
                int current_water_level = accessMat(water_level, row_pos, col_pos);
                if (current_water_level > 0) {
                    float sum_diff = 0;
                    float my_spillage_level = 0;
                    float water_level_float = (current_water_level) * INV_PRECISION;

                    /* Differences between current-cell level and its neighbours  */
                    float current_height =
                        accessMat(p.ground, row_pos, col_pos) + water_level_float;

                    // Iterate over the four neighboring cells using the displacement array
                    spillage_neighbor_1:
                    for (cell_pos = 0; cell_pos < CONTIGUOUS_CELLS; cell_pos++) {
                        #pragma HLS UNROLL
                        new_row = row_pos + displacements[cell_pos][0];
                        new_col = col_pos + displacements[cell_pos][1];

                        float neighbor_height;

                        if (new_row < 0 || new_row >= NROWS || new_col < 0 || new_col >= NCOLS)
                            // Out of borders: Same height as the cell with no water
                            neighbor_height = accessMat(p.ground, row_pos, col_pos);
                        else
                            neighbor_height = accessMat(p.ground, new_row, new_col) +
                                              accessMat(water_level, new_row, new_col)*INV_PRECISION;

                        if (current_height >= neighbor_height) {
                            float height_diff = current_height - neighbor_height;
                            sum_diff += height_diff;
                            my_spillage_level = MAX(my_spillage_level, height_diff);
                        }
                    }
                    my_spillage_level = MIN(water_level_float, my_spillage_level);

                    if (sum_diff > 0.0) {
                        float proportion = my_spillage_level / sum_diff;
                        if (proportion > 1e-8) {
                            accessMat(spillage_flag, row_pos, col_pos) = 1;
                            accessMat(spillage_level, row_pos, col_pos) = my_spillage_level;

                            spillage_neighbor_2:
                            for (cell_pos = 0; cell_pos < 4; cell_pos++) {
                                #pragma HLS UNROLL
                                new_row = row_pos + displacements[cell_pos][0];
                                new_col = col_pos + displacements[cell_pos][1];

                                float neighbor_height;

                                if (new_row < 0 || new_row >= NROWS || new_col < 0 || new_col >= NCOLS) {
                                    // Spillage out of the borders: Water loss
                                    neighbor_height = accessMat(p.ground, row_pos, col_pos);
                                    if (current_height >= neighbor_height) {
                                        r.total_water_loss +=
                                            FIXED(proportion * (current_height - neighbor_height) / 2);
                                    }
                                } else {
                                    neighbor_height = accessMat(p.ground, new_row, new_col) +
                                                      FLOATING(accessMat(water_level, new_row, new_col));
                                    if (current_height >= neighbor_height) {
                                        int depths = CONTIGUOUS_CELLS;
                                        accessMat3D(spillage_from_neigh, new_row, new_col, cell_pos) =
                                            proportion * (current_height - neighbor_height);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


        max_spillage_iter = 0.0;
        propagation_row:
        for (row_pos = 0; row_pos < NROWS; row_pos++) {
            propagation_col:
            for (col_pos = 0; col_pos < NCOLS; col_pos++) {
                #pragma HLS LOOP_FLATTEN
                #pragma HLS pipeline II=1
                if (accessMat(spillage_flag, row_pos, col_pos) == 1) {
                    accessMat(water_level, row_pos, col_pos) -=
                        FIXED(accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR);
                    
                    float spill = accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR;
                    if (spill > max_spillage_iter) {
                        max_spillage_iter = spill;
                    }
                    if (spill > r.max_spillage_scenario) {
                        r.max_spillage_scenario = spill;
                        r.max_spillage_minute = r.minute;
                    }
                }

                // Accumulate spillage from neighbors
                int spillage = 0;

                accumulate_spillage:
                for (cell_pos = 0; cell_pos < CONTIGUOUS_CELLS; cell_pos++) {
                    #pragma HLS UNROLL
                    int depths = CONTIGUOUS_CELLS;
                    spillage +=
                        FIXED(accessMat3D(spillage_from_neigh, row_pos, col_pos, cell_pos) / SPILLAGE_FACTOR);
                    
                    accessMat3D(spillage_from_neigh, row_pos, col_pos, cell_pos) = 0;
                }

                accessMat(water_level, row_pos, col_pos) += spillage;
                accessMat(spillage_flag, row_pos, col_pos) = 0;
                accessMat(spillage_level, row_pos, col_pos) = 0;
            }
        }
    }

    r.max_water_scenario = 0.0;
    statistics_row:
    for (row_pos = 0; row_pos < NROWS; row_pos++) {
        statistics_col:
        for (col_pos = 0; col_pos < NCOLS; col_pos++) {
            #pragma HLS PIPELINE II=1
            if (FLOATING(accessMat(water_level, row_pos, col_pos)) > r.max_water_scenario)
                r.max_water_scenario = FLOATING(accessMat(water_level, row_pos, col_pos));
            r.total_water += accessMat(water_level, row_pos, col_pos);
        }
    }
    return;
}