import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AlibabaGreenService {
  private accessKeyId: string;
  private accessKeySecret: string;
  private endpoint: string;

  constructor(private configService: ConfigService) {
    this.accessKeyId =
      configService.get<string>('ALIBABA_CLOUD_ACCESS_KEY_ID') || '';
    this.accessKeySecret =
      configService.get<string>('ALIBABA_CLOUD_ACCESS_KEY_SECRET') || '';
    this.endpoint = 'https://green-cip.cn-shanghai.aliyuncs.com';
  }

  private sign(
    method: string,
    path: string,
    query: Record<string, string>,
    body: string,
  ): Record<string, string> {
    const nonce = uuidv4();
    const timestamp = new Date().toISOString();
    const params: Record<string, string> = {
      ...query,
      AccessKeyId: this.accessKeyId,
      SignatureMethod: 'HMAC-SHA1',
      SignatureVersion: '1.0',
      SignatureNonce: nonce,
      Timestamp: timestamp,
      Format: 'JSON',
    };

    const sortedKeys = Object.keys(params).sort();
    const canonicalizedQuery = sortedKeys
      .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`)
      .join('&');

    const stringToSign = `${method}&${encodeURIComponent(path)}&${encodeURIComponent(canonicalizedQuery)}`;

    const signature = crypto
      .createHmac('sha1', `${this.accessKeySecret}&`)
      .update(stringToSign)
      .digest('base64');

    params.Signature = signature;
    return params;
  }

  async videoAsyncScan(
    videoUrl: string,
    dataId?: string,
  ): Promise<{ taskId: string; dataId: string }> {
    const body = JSON.stringify({
      scenes: ['porn', 'terrorism'],
      tasks: [
        {
          dataId: dataId || uuidv4(),
          url: videoUrl,
        },
      ],
    });

    const params = this.sign(
      'POST',
      '/green/video/asyncscan',
      { Action: 'VideoAsyncScan' },
      body,
    );
    const queryString = Object.entries(params)
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
      .join('&');

    const res = await axios.post(
      `${this.endpoint}/green/video/asyncscan?${queryString}`,
      body,
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000,
      },
    );

    const task = res.data?.data?.[0];
    return { taskId: task?.taskId || '', dataId: task?.dataId || '' };
  }

  async getVideoResults(
    taskId: string,
  ): Promise<{ passed: boolean; reason: string }> {
    const body = JSON.stringify({ taskIds: [taskId] });
    const params = this.sign(
      'POST',
      '/green/video/results',
      { Action: 'VideoResults' },
      body,
    );
    const queryString = Object.entries(params)
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
      .join('&');

    const res = await axios.post(
      `${this.endpoint}/green/video/results?${queryString}`,
      body,
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000,
      },
    );

    const result = res.data?.data?.[0];
    if (!result) return { passed: true, reason: '无结果' };

    if (result.code === 200) {
      const suggestion = result.results?.[0]?.suggestion;
      if (suggestion === 'pass') return { passed: true, reason: '机审通过' };
      if (suggestion === 'block')
        return {
          passed: false,
          reason: result.results?.[0]?.label || '内容违规',
        };
      return {
        passed: false,
        reason: result.results?.[0]?.label || '审核未通过，需人工复审',
      };
    }

    return { passed: false, reason: result.message || '审核失败' };
  }
}
