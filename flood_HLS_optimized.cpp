#include <stdio.h>

#include "FLOOD.h"

#include "rng.h"

void do_compute(struct parameters p, struct results &r) {

    double max_spillage_iter = p.threshold + 1;

    int water_level[NROWS * NCOLS];
    float spillage_flag[NROWS * NCOLS];
    float spillage_level[NROWS * NCOLS];
    float spillage_from_neigh[NROWS * NCOLS * CONTIGUOUS_CELLS];

    #pragma HLS ARRAY_PARTITION variable=water_level cyclic factor=6 dim=1
    #pragma HLS ARRAY_PARTITION variable=spillage_from_neigh cyclic factor=4 dim=1
initialization_row:
    for (int row_pos = 0; row_pos < NROWS; row_pos++) {
initialization_col:
        for (int col_pos = 0; col_pos < NCOLS; col_pos++) {
            #pragma HLS PIPELINE II=1

            accessMat(water_level, row_pos, col_pos) = 0;
            accessMat(spillage_flag, row_pos, col_pos) = 0.0f;
            accessMat(spillage_level, row_pos, col_pos) = 0.0f;
            int depths = CONTIGUOUS_CELLS;
initialization_depth:
            for (int depth_pos = 0; depth_pos < CONTIGUOUS_CELLS; depth_pos++) {
                #pragma HLS unroll
                accessMat3D(spillage_from_neigh, row_pos, col_pos, depth_pos) = 0.0;
            }
        }
    }

main_minute_loop:
    for (r.minute = 0; r.minute < p.num_minutes && max_spillage_iter > p.threshold; r.minute++) {
        #pragma HLS loop_tripcount min=0 max=NUM_MIN avg=NUM_MIN
        int new_row, new_col;
        int cell_pos;

cloud_movement:
        for (int cloud = 0; cloud < NCLOUDS; cloud++) {
            #pragma HLS pipeline II=1
            // Calculate new position (x are rows, y are columns)
            p.clouds[cloud].x += p.clouds[cloud].dx / 60;
            p.clouds[cloud].y += p.clouds[cloud].dy / 60;
        }

rainfall_cloud:
        for (int cloud = 0; cloud < NCLOUDS; cloud++) {
            float row_start = COORD_SCEN2MAT_Y(MAX(0, p.clouds[cloud].y - p.clouds[cloud].radius));
            float row_end = COORD_SCEN2MAT_Y(MIN(p.clouds[cloud].y + p.clouds[cloud].radius, SCENARIO_SIZE));
            float col_start = COORD_SCEN2MAT_X(MAX(0, p.clouds[cloud].x - p.clouds[cloud].radius));
            float col_end = COORD_SCEN2MAT_X(MIN(p.clouds[cloud].x + p.clouds[cloud].radius, SCENARIO_SIZE));
            float distance;
rainfall_row:
            for (int row_pos = row_start; row_pos < row_end; row_pos++) {
                #pragma HLS loop_tripcount min=0 max=NROWS avg=NROWS
rainfall_col:
                for (int col_pos = col_start; col_pos < col_end; col_pos++) {
                    #pragma HLS PIPELINE II=1
                    #pragma HLS loop_tripcount min=0 max=NCOLS avg=NCOLS
                    
                    float x_pos = COORD_MAT2SCEN_X(col_pos);
                    float y_pos = COORD_MAT2SCEN_Y(row_pos);
                    distance = sqrt(SQR(x_pos - p.clouds[cloud].x) + SQR(y_pos - p.clouds[cloud].y));
                    if (distance < p.clouds[cloud].radius) {
                       float rain =
                            p.ex_factor * MAX(0, p.clouds[cloud].intensity - distance / p.clouds[cloud].radius *
                                                                                   sqrt(p.clouds[cloud].intensity));
                        float meters_per_minute = rain / 1000 / 60;
                        accessMat(water_level, row_pos, col_pos) += FIXED(meters_per_minute);
                        r.total_rain += FIXED(meters_per_minute);
                    }
                }
            }
        }

spillage_row:
        for (int row_pos = 0; row_pos < NROWS; row_pos++) {
spillage_col:
            for (int col_pos = 0; col_pos < NCOLS; col_pos++) {
                #pragma HLS pipeline II=1
                if (accessMat(water_level, row_pos, col_pos) > 0) {
                    float sum_diff = 0;
                    float my_spillage_level = 0;
                    float current_height =
                        accessMat(p.ground, row_pos, col_pos) + FLOATING(accessMat(water_level, row_pos, col_pos));

spillage_neighbor_1:
                    for (int cell_pos = 0; cell_pos < CONTIGUOUS_CELLS; cell_pos++) {
                        #pragma HLS unroll
                        new_row = row_pos + displacements[cell_pos][0];
                        new_col = col_pos + displacements[cell_pos][1];

                        float neighbor_height;

                        if (new_row < 0 || new_row >= NROWS || new_col < 0 || new_col >= NCOLS)
                            // Out of borders: Same height as the cell with no water
                            neighbor_height = accessMat(p.ground, row_pos, col_pos);
                        else
                            neighbor_height = accessMat(p.ground, new_row, new_col) +
                                              FLOATING(accessMat(water_level, new_row, new_col));

                        if (current_height >= neighbor_height) {
                            float height_diff = current_height - neighbor_height;
                            sum_diff += height_diff;
                            my_spillage_level = MAX(my_spillage_level, height_diff);
                        }
                    }
                    my_spillage_level = MIN(FLOATING(accessMat(water_level, row_pos, col_pos)), my_spillage_level);

                    if (sum_diff > 0.0) {
                        float proportion = my_spillage_level / sum_diff;
                        if (proportion > 1e-8) {
                            accessMat(spillage_flag, row_pos, col_pos) = 1;
                            accessMat(spillage_level, row_pos, col_pos) = my_spillage_level;

spillage_neighbor_2:
                            for (int cell_pos = 0; cell_pos < CONTIGUOUS_CELLS; cell_pos++) {
                                #pragma HLS unroll
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
        for (int row_pos = 0; row_pos < NROWS; row_pos++) {
propagation_col:
            for (int col_pos = 0; col_pos < NCOLS; col_pos++) {
                #pragma HLS pipeline II=1
                if (accessMat(spillage_flag, row_pos, col_pos) == 1) {

                    accessMat(water_level, row_pos, col_pos) -=
                        FIXED(accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR);

                    if (accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR > max_spillage_iter) {
                        max_spillage_iter = accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR;
                    }
                    if (accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR > r.max_spillage_scenario) {
                        r.max_spillage_scenario = accessMat(spillage_level, row_pos, col_pos) / SPILLAGE_FACTOR;
                        r.max_spillage_minute = r.minute;
                    }
                }

                // Accumulate spillage from neighbors
accumulate_spillage:
                for (int cell_pos = 0; cell_pos < CONTIGUOUS_CELLS; cell_pos++) {
                    #pragma HLS unroll
                    int depths = CONTIGUOUS_CELLS;
                    accessMat(water_level, row_pos, col_pos) +=
                        FIXED(accessMat3D(spillage_from_neigh, row_pos, col_pos, cell_pos) / SPILLAGE_FACTOR);
                }
            }
        }

reset_rows:
        for (int row_pos = 0; row_pos < NROWS; row_pos++) {
reset_col:
            for (int col_pos = 0; col_pos < NCOLS; col_pos++) {
                #pragma HLS pipeline II=1
                reset_depth:
                for (int cell_pos = 0; cell_pos < CONTIGUOUS_CELLS; cell_pos++) {
                    #pragma HLS unroll
                    int depths = CONTIGUOUS_CELLS;
                    accessMat3D(spillage_from_neigh, row_pos, col_pos, cell_pos) = 0;
                }
                accessMat(spillage_flag, row_pos, col_pos) = 0;
                accessMat(spillage_level, row_pos, col_pos) = 0;
            }
        }
    }

    /* 5. Statistics: Total remaining water and maximum amount of water in a cell */
    r.max_water_scenario = 0.0;
statistics_row:
    for (int row_pos = 0; row_pos < NROWS; row_pos++) {
statistics_col:
        for (int col_pos = 0; col_pos < NCOLS; col_pos++) {
            #pragma HLS pipeline II=1
            if (FLOATING(accessMat(water_level, row_pos, col_pos)) > r.max_water_scenario)
                r.max_water_scenario = FLOATING(accessMat(water_level, row_pos, col_pos));
            r.total_water += accessMat(water_level, row_pos, col_pos);
        }
    }
    return;
}
